defmodule Yubot.Oauth.Github do
  @moduledoc """
  Handler for OAuth2 server-side flow for GitHub.
  """

  use Yubot.Oauth,
    env_prefix: "github",
    redirect_url: SolomonLib.Env.default_base_url(:yubot) <> "/oauth/github/callback",
    authorize_url: "https://github.com/login/oauth/authorize",
    token_url: "https://github.com/login/oauth/access_token"

  def authorize_url_for_user_info!(return_path) do
    # XXX: might be better scrambling `return_path`?
    authorize_url!(scope: "user", state: return_path)
  end
end
