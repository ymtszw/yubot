use Croma

defmodule Yubot.AsyncJob.PollObserver do
  @moduledoc """
  Observer job to fetch and register `Yubot.AsyncJob.PollWorker` jobs for Polls.

  - Runs indefinitely at minutely interval (ScheduledJob).
  - Fetches Polls with `is_enabled: true` and has `:next_run_at` timestamp older than fetch time.
      - Currently it assumes number of Polls to execute at a given moment will not exceed 1000.
          - A single Dodai retrieve_list request can only return up to 1000 entities.
          - Job queues for `Antikythera.AsyncJob` per executor pool currently only accept up to 1000 jobs at a moment.
      - This assumption will eventually negated as Users and Polls grow, so:
      - TODO: Properly limit or control global number of Polls to be executed at a moment.
          - Current planned solution: Poll Capacity per User, see `Yubot.Model.User` and `Yubot.Model.Poll`.
          - Though the above may not be enough. Further measures may be required.
  """

  alias Croma.Result, as: R
  use Antikythera.AsyncJob
  alias Antikythera.{Context, Cron, AsyncJob}
  alias Yubot.Logger, as: L
  alias Yubot.Repo.Poll
  alias Yubot.AsyncJob.PollWorker

  @type payload :: %{String.t => Dodai.GroupId.t}

  @epool_id {:gear, :yubot} # XXX: Use tenant executor pool?
  @schedule {:cron, Cron.parse!("* * * * *")}

  @impl true
  defun run(%{"group_id" => gi} :: payload, %AsyncJob.Metadata{run_at: ra}, %Context{} = c) :: :ok do
    rkey = Yubot.Dodai.root_key()
    case Poll.retrieve_executables(ra, rkey, gi) do
      {:ok, []}    -> L.debug("Nothing to register.")
      {:ok, polls} -> register_workers(polls, rkey, gi, c)
      e            -> L.error("Cannot retrieve executable Polls!: #{inspect(e)}")
    end
  end

  defp register_workers(polls, key, group_id, context) do
    Enum.map(polls, fn poll ->
      case PollWorker.register(poll, key, group_id, context) do
        {:ok, id} -> L.debug("Job registered: #{inspect(id)}")
        e         -> L.error("Cannot register Job!: #{inspect(e)}")
      end
    end)
    :ok
  end

  defun register(group_id :: v[Dodai.GroupId.t] \\ Yubot.Dodai.default_group_id()) :: R.t(AsyncJob.Id.t) do
    register(%{"group_id" => group_id}, @epool_id, [
      id:           job_id(group_id),
      attempts:     1,
      max_duration: 50_000,
      schedule:     @schedule,
    ])
  end

  defun status(group_id \\ Yubot.Dodai.default_group_id()) :: R.t(AsyncJob.Status.t) do
    AsyncJob.status(@epool_id, job_id(group_id))
  end

  def job_id(group_id), do: "Yubot-PollObserver-#{group_id}"
end
