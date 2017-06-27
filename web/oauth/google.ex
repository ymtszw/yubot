defmodule Yubot.Oauth.Google do
  @moduledoc """
  Handler for OAuth2 server-side flow for Google.
  """

  @redirect_url (if SolomonLib.Env.compiling_for_cloud?() do
     SolomonLib.Env.default_base_url(:yubot) <> "/oauth/google/callback"
  else
    # This path won't work obviously, though Google only allows "http://localhost" for local development.
    "http://localhost:8080/oauth/google/callback"
  end)

  use Yubot.Oauth,
    env_prefix: "google",
    redirect_url: @redirect_url,
    authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
    token_url: "https://www.googleapis.com/oauth2/v4/token"

  def authorize_url_for_user_info!(return_path) do
    # XXX: might be better scrambling `return_path`?
    authorize_url!(state: return_path,
      scope: "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email")
  end
end
