use Croma

defmodule Yubot.Oauth.Credentials do
  use Croma.Struct, fields: [
    access_token: Croma.String,
    expires_at: Croma.TypeGen.nilable(Antikythera.Time),
    refresh_token: Croma.TypeGen.nilable(Croma.String),
  ]
end
