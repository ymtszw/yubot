use Croma

defmodule Yubot.Controller.Oauth do
  alias Croma.Result, as: R
  alias SolomonLib.Request, as: Req
  use Yubot.Controller
  alias Yubot.{Oauth, External}
  alias Yubot.Model.User

  @key Yubot.Plug.Auth.session_key()
  plug SolomonLib.Plug.Session, :load, key: @key

  # GET /oauth/:provider/login
  def login(%Conn{request: %Req{path_matches: pm, query_params: qp}} = conn) do
    conn
    |> delete_session(@key)
    |> redirect(authorize_url(pm.provider, Yubot.encrypt_base64(qp["return_path"])))
  end

  defp authorize_url("google", return_path), do: Oauth.Google.authorize_url_for_user_info!(return_path)
  defp authorize_url("github", return_path), do: Oauth.Github.authorize_url_for_user_info!(return_path)

  # GET /oauth/:provider/callback
  def callback(%Conn{request: %Req{path_matches: pm, query_params: qp}} = conn) do
    R.m do
      return_path <- Yubot.decrypt_base64(qp["state"])
      access_token <- code_to_token(pm.provider, qp["code"])
      {email, display_name} <- fetch_email_and_display_name(pm.provider, access_token)
      user <- login_or_create_user(email, display_name)
      pure {return_path, user}
    end
    |> handle(conn, fn {return_path, %User{session: %Yubot.Dodai.Session{key: user_key}}}, conn ->
      conn
      |> put_session(@key, Yubot.encrypt_base64(user_key))
      |> redirect(return_path)
    end)
  end

  defp code_to_token("google", code) do
    Oauth.Google.code_to_token(code) |> R.map(&(&1.token.access_token))
  end
  defp code_to_token("github", code) do
    Oauth.Github.code_to_token(code) |> R.map(&(&1.token.access_token))
  end

  defp fetch_email_and_display_name("google", token), do: External.Google.retrieve_self(token)
  defp fetch_email_and_display_name("github", token), do: External.Github.retrieve_self(token)

  defp login_or_create_user(email, display_name) do
    root_key = Yubot.Dodai.root_key()
    case User.login(%{email: email, password: root_key}, root_key) do
      {:ok, user} ->
        {:ok, user} # TODO: update to latest display_name if necessary
      {:error, %Dodai.AuthenticationError{}} ->
        User.insert(%{email: email, password: random_password(), data: %{display_name: display_name}}, root_key)
    end
  end

  defp random_password(), do: :crypto.strong_rand_bytes(32) |> Base.encode64()
end
