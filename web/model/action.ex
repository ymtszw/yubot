use Croma

defmodule Yubot.Model.Action do
  @moduledoc """
  HTTP action object.
  """

  alias Yubot.Model.Authentication

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [
      :http,
      :hipchat,
    ], default: :http
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    label: Croma.TypeGen.nilable(Croma.String),
    method: SolomonLib.Http.Method,
    url: SolomonLib.Url,
    auth: Croma.TypeGen.nilable(Authentication.Id),
    body_template: Yubot.StringTemplate,
    type: Type,
  ]
end
