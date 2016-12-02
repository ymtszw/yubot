defmodule Yubot.Controller.Hello do
  use SolomonLib.Controller

  def hello(conn) do
    Yubot.Gettext.put_locale(conn.request.query_params["locale"] || "en")
    render(conn, 200, "hello", [gear_name: :yubot])
  end
end
