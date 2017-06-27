defmodule Yubot.Oauth do
  @moduledoc """
  OAuth2 strategy module generator. Wrapping behaviour module `OAuth2.Strategy`.

  Generate `client/0`, `authorize_url!/1`, `code_to_token/2`.

  ## Usage

      defmodule YourGear.Oauth.SomeProvider do
        use #{inspect(__MODULE__)}, env_prefix "some_provider",
          redirect_path: "/oauth/callback",
          authorize_url: "https://some.provider.com/oauth2/auth",
          token_url: "https://some.provider.com/oauth2/token"
      end

  You may override private `redirect_url/0`. In that case, `:redirect_path` is unnecessary.

  Next steps will be:

  0. Set "some_provider_client_id" and "some_provider_client_secret" in your gear config
  1. Set up login page (route) and callback route ("/oauth/callback" in above example)
  2. Redirect attempting users to `YourGear.Oauth.SomeProvider.authorize_url!/1`, with arbitrary `params`
      - Unless default scopes are applied by the provider,
        you must manually specify "scope" query parameter according to the provider's specifications.
          - e.g. To access user information in GitHub, you need to set `scope: "user"`
      - Utilize "state" query parameter to ensure current session, or keep return path after authorization
  3. After authorization, fetch authorization_code on callback route. It should be in "code" query parameter along with "state"
  4. Exchange authorization_code for access_token using `YourGear.Oauth.SomeProvider.code_to_token/2`.
  5. On success, the response should be `{:ok, %OAuth2.AccessToken{}}`.
    The struct contains access_token (and refresh_token, for offline access). Use them to request the provider's APIs.
      - Probably you want to fetch user information from the provider API here,
        and possibly create or retrieve corresponding user information in your application.
  6. Finally you will have to redirect the user to actual application path, with session information indicating successful login.
      - Use cookie or whatever means of session management.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour OAuth2.Strategy

      @env_prefix    Keyword.fetch!(opts, :env_prefix)
      @authorize_url Keyword.fetch!(opts, :authorize_url)
      @token_url     Keyword.fetch!(opts, :token_url)

      # Public APIs

      def client() do
        Yubot.Oauth.client_impl(__MODULE__, @env_prefix, redirect_url(), @authorize_url, @token_url)
      end

      def authorize_url!(params) do
        OAuth2.Client.authorize_url!(client(), params)
      end

      def code_to_token(code, opts \\ []) do
        OAuth2.Client.get_token(client(), [code: code], [], opts)
      end

      # Callbacks

      @doc false
      def authorize_url(c, p) do
        OAuth2.Strategy.AuthCode.authorize_url(c, p)
      end

      @doc false
      def get_token(c, p, h) do
        c
        |> OAuth2.Client.put_param(:client_secret, c.client_secret)
        |> OAuth2.Client.put_header("accept", "application/json")
        |> OAuth2.Strategy.AuthCode.get_token(p, h)
      end

      @doc false
      @redirect_path opts[:redirect_path]
      defp redirect_url(), do: "#{SolomonLib.Env.default_base_url(:yubot)}#{@redirect_path}"

      defoverridable [redirect_url: 0]
    end
  end

  @doc false
  def client_impl(module, env_prefix, redirect_uri, authorize_url, token_url) do
    OAuth2.Client.new([
      strategy: module,
      client_id: Yubot.get_env("#{env_prefix}_client_id"),
      client_secret: Yubot.get_env("#{env_prefix}_client_secret"),
      redirect_uri: redirect_uri,
      authorize_url: authorize_url,
      token_url: token_url,
    ])
  end
end
