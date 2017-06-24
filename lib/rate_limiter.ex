use Croma

defmodule Yubot.RateLimiter do
  @sweep_timeout (if Mix.env() == :test, do: 500, else: 30_000)

  @moduledoc """
  Manager server of rate-limits for arbitrary purposes.

  It accepts incremental counts via `push/2` API, and tells callers whether the target has reached rate limit.

  # Mechanism

  `#{inspect(__MODULE__)}` is `gen_server` which holds rate limit status in `state` format:

      %{
        {target1, 10} => {1, {SolomonLib.Time, {2017, 6, 1}, {9, 1, 0}, 0}},
        {target1, 50} => {1, {SolomonLib.Time, {2017, 6, 1}, {9, 10, 0}, 0}},
        ...
      }

  `target1` is arbitrary target to which rate limits are applied. Such as `{:web, "127.0.0.1"}`.

  In the above example, `target1` has two rate limit units: 10 counts per 1 minute AND 50 counts per 10 minutes.

  - If more than 10 counts are accumulated in 1 minute window, `target1` is considered "limit reached" until the 1-minute window expires
  - If more than 50 counts are accumulated in 10 minutes window, with or without violating "10-per-1-minute" limit on the way,
    `target1` is considered "limit reached" until the 10-minute window expires

  Therefore, in this case, `target1` can keep accumulating counts without reaching limit if it:

  - counts with the rate slower than 50-per-10-minutes, AND,
  - is not surpassing the rate of 10-per-minute at any timeframes within the 10 minutes window

  Expired (already reset) limit entries will be sweeped at #{@sweep_timeout}ms interval.
  The sweeping will check whole `state` every time, so it can be a bottleneck as the number of targets grows.

  In order not to inflate size of `state`, only up to 3 limit_units per target can be applied.
  """

  use GenServer
  alias SolomonLib.Time

  @type limit_unit :: {target :: any, max_count :: non_neg_integer}
  @type unit_state :: {current_count :: non_neg_integer, reset_at :: Time.t}
  @type state :: %{limit_unit => unit_state}

  def child_spec() do
    Supervisor.Spec.worker(__MODULE__, [])
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defun init(nil) :: {:ok, state} do
    schedule_sweep()
    {:ok, %{}}
  end

  defp schedule_sweep(), do: Process.send_after(self(), :sweep, @sweep_timeout)

  def handle_call({:push, target, limit_units}, _from, old_state) do
    {limit_reached?, new_state} = Enum.reduce(limit_units, {false, old_state}, &get_and_update_unit_state(target, &1, &2))
    {:reply, limit_reached?, new_state}
  end
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  def handle_call(_, _from, state) do
    {:noreply, state}
  end

  defp get_and_update_unit_state(target, {max_count, reset_in_ms}, {limit_already_reached?, state0}) do
    now = Time.now()
    {limit_now_reached?, state1} =
      Map.get_and_update(state0, {target, max_count}, fn
        nil ->
          {false, {1, Time.shift_milliseconds(now, reset_in_ms)}}
        {current_count, reset_in} ->
          if now < reset_in do
            {current_count >= max_count, {current_count + 1, reset_in}}
          else
            {false, {1, Time.shift_milliseconds(now, reset_in_ms)}}
          end
      end)
    {limit_already_reached? or limit_now_reached?, state1}
  end

  def handle_info(:sweep, old_state) do
    now = Time.now()
    new_state = :maps.filter(fn _limit_unit, {_current_count, reset_in} -> reset_in > now end, old_state)
    schedule_sweep()
    {:noreply, new_state}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end

  def call_with_dynamically_start_child(request) do
    try do
      GenServer.call(__MODULE__, request)
    catch
      :exit, {:noproc, {GenServer, :call, [__MODULE__, ^request, _]}} ->
        Supervisor.start_child(Yubot.Supervisor, child_spec())
        GenServer.call(__MODULE__, request)
    end
  end

  #
  # API
  #

  def get_state(), do: call_with_dynamically_start_child(:get_state)

  @doc """
  Increment count of `target`, with `limit_units` applied.

  Returns `boolean` indicating whether rate limit is reached. `true` when reached any of the limits.

  You may apply up to 3 `limit_units` per `target`.
  """
  def push(target, limit_units) when length(limit_units) <= 3 do
    call_with_dynamically_start_child({:push, target, limit_units})
  end
end
