use Croma

defmodule Yubot.Model.Action do
  @moduledoc """
  HTTP action object.
  """

  alias Croma.Result, as: R
  alias Yubot.StringTemplate
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

  defun parse_template_and_insert(%{data: %{"body_template" => bt0}} = ia0 :: insert_action_t, key :: v[String.t], group_id :: v[Dodai.GroupId.t]) :: R.t(t) do
    StringTemplate.parse(bt0)
    |> R.bind(&insert(put_in(ia0.data["body_template"], &1), key, group_id))
  end
end
