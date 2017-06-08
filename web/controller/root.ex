defmodule Yubot.Controller.Root do
  use Yubot.Controller

  # GET /
  def index(conn) do
    render(conn, 200, "index", gear_name: :yubot)
  end

  # GET /poller/*path
  def poller(conn) do
    params = [
      title: "Poller the Bear",
      filename: "poller.js",
      favicon: "img/poller/favicon.ico",
      flags: %{
        isDev: !SolomonLib.Env.running_in_cloud?,
      },
    ]
    render(conn, 200, "poller", params, layout: :elm_ui)
  end
end
