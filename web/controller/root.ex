use Croma

defmodule Yubot.Controller.Root do
  use Yubot.Controller
  alias Yubot.Repo.Users

  @key Yubot.Plug.Auth.session_key()
  plug Antikythera.Plug.Session, :load, [key: @key], except: [:index]

  # GET /
  def index(conn) do
    Conn.render(conn, 200, "index", title: "Yubot Index")
  end

  # GET /fib
  def fib(conn) do
    Conn.render(conn, 200, "fib", title: "Fib!")
  end

  # GET /poller/*path
  def poller(conn) do
    params = [
      title: "Poller the Bear",
      filename: "dist/poller.js",
      favicon: "img/poller/favicon.ico",
      flags: %{
        isDev: !Antikythera.Env.running_in_cloud?(),
        user: nil_or_user(conn),
        assets: Enum.map(Yubot.Asset.all(), &Tuple.to_list/1), # Converts to flag-compatible data type for Elm interop
      },
    ]
    Conn.render(conn, 200, "poller", params, layout: :elm_ui)
  end

  # `user: nil` indicates requesting user cannot be identified; client app should prompt login
  defp nil_or_user(conn) do
    case Conn.get_session(conn, @key) do
      nil -> nil
      base64_key -> retrieve_self_or_log_error(base64_key, conn)
    end
  end

  defp retrieve_self_or_log_error(base64_key, conn) do
    with {:ok, user_key} <- Yubot.decrypt_base64(base64_key),
      {:ok, user} <- Users.retrieve_self(user_key, Util.group_id(conn))
    do
      user
    else
      e ->
        Yubot.Logger.debug(inspect(e))
        nil
    end
  end
end
