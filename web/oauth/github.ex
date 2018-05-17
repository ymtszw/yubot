defmodule Yubot.Oauth.Github do
  @moduledoc """
  Handler for OAuth2 server-side flow for GitHub.
  """

  alias AntikytheraAcs.Oauth2, as: GO

  def authorize_url_for_user_info!(return_path) do
    # XXX: might be better scrambling `return_path`?
    GO.authorize_url!(client(), scope: "user", state: return_path)
  end

  def client() do
    %{"github_client_id" => id, "github_client_secret" => secret} = Yubot.get_all_env()
    GO.Provider.Github.client(id, secret, Antikythera.Env.default_base_url(:yubot) <> "/oauth/github/callback")
  end
end
