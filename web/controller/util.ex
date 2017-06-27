defmodule Yubot.Controller.Util do
  def group_id(conn) do
    case conn.request.headers["x-yubot-blackbox"] do
      "true" ->
        Yubot.Dodai.test_group_id()
      _otherwise ->
        Yubot.Dodai.default_group_id()
    end
  end

  # Require any authentication plug
  def key(conn) do
    case conn.request.headers["x-yubot-blackbox"] do
      "true" ->
        Yubot.Dodai.root_key()
      _otherwise ->
        conn.assigns.key
    end
  end
end
