use Croma

defmodule Yubot.Controller.Root do
  alias Croma.Result, as: R
  use Yubot.Controller
  alias Yubot.Model.User

  @key Yubot.Plug.Auth.session_key()
  plug SolomonLib.Plug.Session, :load, [key: @key], except: [:index]

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
        user: nil_or_user(conn),
      },
    ]
    render(conn, 200, "poller", params, layout: :elm_ui)
  end

  # `user: nil` indicates requesting user cannot be identified; client app should prompt login
  defp nil_or_user(conn) do
    case get_session(conn, @key) do
      nil -> nil
      base64_key ->
        Yubot.decrypt_base64(base64_key)
        |> R.bind(&User.retrieve_self(&1, group_id(conn)))
        |> R.get(nil)
    end
  end
end
