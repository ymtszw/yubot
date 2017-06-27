use Croma

defmodule Yubot.NilableTime do
  use Yubot.TypeGen.Nilable, module: SolomonLib.Time
end

defmodule Yubot.Oauth.Credentials do
  use Croma.Struct, fields: [
    access_token: Croma.String,
    expires_at: Yubot.NilableTime,
    refresh_token: Croma.TypeGen.nilable(Croma.String),
  ]
end
