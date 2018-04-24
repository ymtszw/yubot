defmodule Yubot.Plug.Auth do
  use SolomonLib.Controller
  alias Yubot.Controller.Result

  @key "yubot_session"
  def session_key(), do: @key

  def cookie_only(conn, opts \\ []) do
    conn
    |> SolomonLib.Plug.Session.load(Keyword.merge(opts, key: @key))
    |> unauthorized_without_session(&Conn.json(&1, 401, %{"error" => "unauthorized"}))
  end

  def cookie_or_header(conn, opts \\ []) do
    conn
    |> SolomonLib.Plug.Session.load(Keyword.merge(opts, key: @key))
    |> unauthorized_without_session(fn conn ->
      case conn.request.headers["authorization"] do
        nil ->
          Conn.json(conn, 401, %{"error" => "unauthorized"})
        user_key ->
          Conn.assign(conn, :key, user_key)
      end
    end)
  end

  defp unauthorized_without_session(conn, without_cookie_fun) do
    case Conn.get_session(conn, @key) do
      nil ->
        without_cookie_fun.(conn)
      base64_key ->
        Yubot.decrypt_base64(base64_key) |> Result.handle(conn, &Conn.assign(&2, :key, &1))
    end
  end
end
