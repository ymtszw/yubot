use Croma

defmodule Yubot.Controller.Oauth do
  alias Croma.Result, as: R
  alias Antikythera.Request, as: Req
  alias AntikytheraAcs.Oauth2, as: GO
  use Yubot.Controller
  alias Yubot.{Oauth, External}
  alias Yubot.Repo.Users
  alias Yubot.Model.User

  @key Yubot.Plug.Auth.session_key()
  plug Antikythera.Plug.Session, :load, key: @key

  # GET /oauth/:provider/login
  def login(%Conn{request: %Req{path_matches: pm, query_params: qp}} = conn) do
    conn
    |> Conn.delete_session(@key)
    |> Conn.redirect(authorize_url(pm.provider, Yubot.encrypt_base64(qp["return_path"])))
  end

  defp authorize_url("google", return_path), do: Oauth.Google.authorize_url_for_user_info!(return_path)
  defp authorize_url("github", return_path), do: Oauth.Github.authorize_url_for_user_info!(return_path)

  # GET /oauth/:provider/callback
  def callback(%Conn{request: %Req{path_matches: pm, query_params: qp}} = conn) do
    R.m do
      return_path <- Yubot.decrypt_base64(qp["state"])
      %OAuth2.AccessToken{access_token: access_token} <- code_to_token(pm.provider, qp["code"])
      {email, display_name} <- fetch_email_and_display_name(pm.provider, access_token)
      user <- login_or_create_user(email, display_name)
      pure {return_path, user}
    end
    |> Result.handle(conn, fn({return_path, %User{session: %Dodai.Model.Session{key: user_key}}}, conn) ->
      conn
      |> Conn.put_session(@key, Yubot.encrypt_base64(user_key))
      |> Conn.redirect(return_path)
    end)
  end

  defp code_to_token("google", code), do: GO.code_to_token(Oauth.Google.client(), code, [])
  defp code_to_token("github", code), do: GO.code_to_token(Oauth.Github.client(), code, [])

  defp fetch_email_and_display_name("google", token), do: External.Google.retrieve_self(token)
  defp fetch_email_and_display_name("github", token), do: External.Github.retrieve_self(token)

  @default_session_life_time_in_sec 14 * 24 * 3_600

  defp login_or_create_user(email, display_name) do
    root_key = Yubot.Dodai.root_key()
    case Users.login(%{email: email, password: root_key, sessionLifetime: @default_session_life_time_in_sec}, root_key) do
      {:ok, user} ->
        {:ok, user} # TODO: update to latest display_name if necessary
      {:error, %Dodai.AuthenticationError{}} ->
        %{
          email: email,
          password: random_password(),
          sessionLifetime: @default_session_life_time_in_sec,
          data: %{display_name: display_name},
        }
        |> Users.register(root_key)
      other_error ->
        other_error
    end
  end

  defp random_password(), do: :crypto.strong_rand_bytes(32) |> Base.encode64()
end
