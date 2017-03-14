defmodule Yubot.Controller.Root do
  use SolomonLib.Controller

  def index(conn) do
    render(conn, 200, "index", gear_name: :yubot)
  end
end
