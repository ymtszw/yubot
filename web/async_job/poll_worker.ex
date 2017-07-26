use Croma

defmodule Yubot.AsyncJob.PollWorker do
  @short_duration_in_seconds 10
  @long_duration_in_seconds 60
  @moduledoc """
  Worker job to execute a Poll.

  Registered by `Yubot.AsyncJob.PollObserver` job.

  Max duration of Poll executions are limited by their intervals:
  - 1-, 3-, 10-minute polls: #{@short_duration_in_seconds} seconds
  - 30-minute, hourly, daily polls: #{@long_duration_in_seconds} seconds

  All Polls will "just fail" when something went wrong and not be retried via AsyncJob's retry.
  Instead, they will be retried when they are re-registered at next scheduled time.
  """

  alias Croma.Result, as: R
  use SolomonLib.AsyncJob
  alias SolomonLib.Context
  alias SolomonLib.AsyncJob.Metadata
  alias Yubot.Logger, as: L
  alias Yubot.Model.Poll
  alias Yubot.Service.RunPoll

  defmodule Payload do
    use Croma.Struct, fields: [
      poll: Poll,
      key: Croma.String,
      group_id: Dodai.GroupId,
    ]
  end

  defun run(%Payload{poll: %Poll{data: d} = p, key: k, group_id: gi}, %Metadata{run_at: ra} = md, _context :: Context.t) :: :ok do
    R.m do
      _scheduled  <- Poll.schedule_next(p, ra, k, gi)
      exec_result <- RunPoll.exec(d, k, gi, false)
      Poll.HistoryEntry.from_tuple(exec_result, ra)
    end
    |> handle_result(p, md, k, gi)
  end

  defp handle_result({:ok, %Poll.HistoryEntry{poll_result: %Poll.PollResult{status: 304}}}, _, _, _, _) do
    L.debug("Poll successfully executed but the target has not modified.")
  end
  defp handle_result({:ok, entry}, %Poll{_id: id}, _, k, gi) do
    {:ok, p} = Poll.record_history(entry, id, k, gi)
    L.debug("""
    Poll successfully executed:
      #{inspect(p)}
    """)
  end
  defp handle_result(e, %Poll{_id: id}, %Metadata{run_at: ra} = md, k, gi) do
    {:ok, p} = Poll.disable_with_error_history(e, ra, id, k, gi)
    L.error("""
    Poll executed but failed, then disabled:
      #{inspect(p)}

    Error from PollWorker:
      #{inspect(e)}

    Metadata:
      #{inspect(md)}
    """)
    # TODO: Notify owner user appropriately. Currently just dump to error log (thus trigger email to developer)
  end

  @doc false
  defun register(%Poll{data: %Poll.Data{interval: i}} = poll,
                 key :: v[String.t],
                 group_id :: v[Dodai.GroupId.t],
                 %Context{executor_pool_id: epool_id}) :: R.t(SolomonLib.AsyncJob.Id.t) do
    Payload.new(%{poll: poll, key: key, group_id: group_id})
    |> R.bind(fn payload ->
      register(payload, epool_id, [
        attempts: 1,
        max_duration: interval_to_max_duration(i),
      ])
    end)
  end

  defp interval_to_max_duration(short) when short in ["1", "3", "10"], do: @short_duration_in_seconds * 1_000
  defp interval_to_max_duration(_long), do: @long_duration_in_seconds * 1_000
end
