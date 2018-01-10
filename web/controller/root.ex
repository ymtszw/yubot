use Croma

defmodule Yubot.Controller.Root do
  use Yubot.Controller
  alias Yubot.Repo.Users

  @key Yubot.Plug.Auth.session_key()
  plug SolomonLib.Plug.Session, :load, [key: @key], except: [:index]

  # GET /
  def index(conn) do
    render(conn, 200, "index", gear_name: :yubot)
  end

  # GET /fib
  def fib(conn) do
    render(conn, 200, "fib", title: "Fib!")
  end

  # GET /poller/*path
  def poller(conn) do
    params = [
      title: "Poller the Bear",
      filename: "dist/poller.js",
      favicon: "img/poller/favicon.ico",
      flags: %{
        isDev: !SolomonLib.Env.running_in_cloud?(),
        user: nil_or_user(conn),
        assets: Enum.map(Yubot.Asset.all(), &Tuple.to_list/1), # Converts to flag-compatible data type for Elm interop
      },
    ]
    render(conn, 200, "poller", params, layout: :elm_ui)
  end

  # `user: nil` indicates requesting user cannot be identified; client app should prompt login
  defp nil_or_user(conn) do
    case get_session(conn, @key) do
      nil -> nil
      base64_key -> retrieve_self_or_log_error(base64_key, conn)
    end
  end

  defp retrieve_self_or_log_error(base64_key, conn) do
    with {:ok, user_key} <- Yubot.decrypt_base64(base64_key),
      {:ok, user} <- Users.retrieve_self(user_key, group_id(conn))
    do
      user
    else
      e ->
        Yubot.Logger.debug(inspect(e))
        nil
    end
  end
end
