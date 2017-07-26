defmodule Yubot.BigBoss do
  use GenServer

  def child_spec() do
    Supervisor.Spec.worker(__MODULE__, [])
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @startup_timeout 5_000

  def init(nil) do
    {:ok, nil, @startup_timeout}
  end

  def handle_info(:timeout, nil) do
    Yubot.AsyncJob.PollObserver.register()
    {:noreply, nil}
  end
  def handle_info(_, nil) do
    {:noreply, nil}
  end
end
