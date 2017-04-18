defmodule Yubot.Controller.Root do
  use Yubot.Controller

  def index(conn) do
    render(conn, 200, "index", gear_name: :yubot)
  end

  def poller(conn) do
    render(conn, 200, "poller", [title: "Poller the Bear", filename: "poller.js", favicon: "img/poller/favicon.ico"], layout: :elm_ui)
  end
end
