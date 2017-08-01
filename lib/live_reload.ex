# Should only be compiled for local; FileSystem is only available in Mix.env == :dev
if Mix.env == :dev do
  defmodule Yubot.LiveReload do
    @priv_static_dir ["priv", "static"] |> Path.join() |> Path.expand()
    @ebin_dir        :code.lib_dir(:yubot) |> Path.join("ebin")
    @template_module Path.join(@ebin_dir, "Elixir.Yubot.Template.beam")

    use GenServer

    def child_spec() do
      Supervisor.Spec.worker(__MODULE__, [])
    end

    def start_link() do
      GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def init(nil) do
      {:ok, watcher_pid} = FileSystem.start_link(dirs: [@priv_static_dir, @ebin_dir])
      FileSystem.subscribe(watcher_pid)
      {:ok, %{watcher_pid: watcher_pid}}
    end

    def handle_info({:file_event, watcher_pid, {@priv_static_dir <> _file_path, _events}}, %{watcher_pid: watcher_pid} = state) do
      Yubot.Websocket.broadcast_reload()
      {:noreply, state}
    end
    def handle_info({:file_event, watcher_pid, {@template_module              , _events}}, %{watcher_pid: watcher_pid} = state) do
      Yubot.Websocket.broadcast_reload()
      {:noreply, state}
    end
    def handle_info(_other, state) do # Includes :stop event of FileSystem
      {:noreply, state}
    end
  end
end
