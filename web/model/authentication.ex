use Croma

defmodule Yubot.Model.Authentication do
  @moduledoc """
  Authentication object for both polling endpoint and action target endpoint.
  """

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [:raw, :bearer]
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    name: Croma.String,
    type: Type,
    token: Croma.TypeGen.nilable(Croma.String),
  ]
end
