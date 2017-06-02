# Should only be compiled for local; ExFSWatch is only available in Mix.env == :dev
if Mix.env == :dev do
  defmodule Yubot.LiveReload do
    @priv_static_dir ["priv", "static"] |> Path.join() |> Path.expand()
    @ebin_dir        :code.lib_dir(:yubot) |> Path.join("ebin")
    @template_module Path.join(@ebin_dir, "Elixir.Yubot.Template.beam")
    use ExFSWatch, dirs: [@priv_static_dir, @ebin_dir]

    def callback(:stop) do
      :ok
    end

    def callback(@priv_static_dir <> _file_path, _events) do
      Yubot.Websocket.broadcast_reload()
    end
    def callback(@template_module, _events) do
      Yubot.Websocket.broadcast_reload()
    end
    def callback(_other, _events) do
      :ok
    end
  end
end
