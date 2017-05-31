# Should only be compiled for local; ExFSWatch is only available in Mix.env == :dev
if Mix.env == :dev do
  defmodule Yubot.LiveReload do
    @priv_static_dir [__DIR__, "..", "priv", "static"] |> Path.join() |> Path.expand()
    use ExFSWatch, dirs: [@priv_static_dir]

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
