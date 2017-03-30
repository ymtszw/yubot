use Croma

defmodule Yubot.Model.Action do
  alias Yubot.Model.Authentication

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    method: SolomonLib.Http.Method,
    url: SolomonLib.Url,
    auth: Croma.TypeGen.nilable(Authentication.Id),
    body_template: Yubot.StringTemplate,
  ]
end
