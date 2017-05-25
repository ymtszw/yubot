# Should only be compiled for local; ExFSWatch is only available in Mix.env == :dev
if Mix.env == :dev do
  defmodule Yubot.LiveReload do
    @priv_static_dir [__DIR__, "..", "priv", "static"] |> Path.join() |> Path.expand()
    use ExFSWatch, dirs: [@priv_static_dir] # Injects `start/0`

    @doc """
    Start ExFSWatch worker, then notify `:ignore` to Gear supervisor so that it wont't be looked back.
    """
    def start_link() do
      {:ok, _pid} = start() # Worker process will be supervised by ExFSWatch.Supervisor; Gear supervisor does not have to care about it.
      :ignore
    end

    def callback(:stop) do
      :ok
    end

    def callback(@priv_static_dir <> _file_path, _events) do
      Yubot.Websocket.broadcast_reload()
    end
    def callback(_other, _events) do
      :ok
    end
  end
end
