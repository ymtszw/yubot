defmodule Yubot.Oauth.Google do
  @moduledoc """
  Handler for OAuth2 server-side flow for Google.
  """

  alias GearLib.Oauth2, as: GO

  def authorize_url_for_user_info!(return_path) do
    # XXX: might be better scrambling `return_path`?
    GO.authorize_url!(client(), [
      scope: "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email",
      state: return_path,
    ])
  end

  def client() do
    %{"google_client_id" => id, "google_client_secret" => secret} = Yubot.get_all_env()
    GO.Provider.Google.client(id, secret, redirect_url())
  end

  if SolomonLib.Env.compiling_for_cloud?() do
    defp redirect_url(), do: SolomonLib.Env.default_base_url(:yubot) <> "/oauth/google/callback"
  else
    # This path won't work obviously, though Google only allows "http://localhost" for local development.
    defp redirect_url(), do: "http://localhost:8080/oauth/google/callback"
  end
end
