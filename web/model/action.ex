use Croma

defmodule Yubot.Model.Action do
  @moduledoc """
  HTTP action object.
  """

  alias Yubot.StringTemplate, as: ST
  alias Yubot.External.Http, as: ExHttp
  alias Yubot.Model.Authentication

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [
      :http,
      :hipchat,
    ], default: :http
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    label: Croma.String,
    method: SolomonLib.Http.Method,
    url: SolomonLib.Url,
    auth_id: Croma.TypeGen.nilable(Authentication.Id),
    body_template: ST,
    type: Type,
  ]

  defmodule TrialValues do
    use Croma.SubtypeOfMap, key_module: Croma.String, value_module: Croma.String
  end

  defmodule TrialRequest do
    use Croma.Struct, recursive?: true, fields: [
      data: Data,
      trial_values: TrialValues,
    ]
  end

  @doc """
  Execute an Action with `dict` as material.

  It also records elapsed time for the Action.
  """
  def exec(%TrialRequest{data: d, trial_values: dict}, nil_or_auth) do
    exec(d, dict, nil_or_auth)
  end
  def exec(%Data{method: m, url: u, body_template: b}, dict, nil_or_auth) do
    ST.render(b, dict)
    |> Croma.Result.bind(&ExHttp.request(m, u, httpc_body(&1), nil_or_auth))
  end

  defp httpc_body(""), do: ""
  defp httpc_body(rendered_body) do
    case Poison.decode(rendered_body) do
      {:ok, json} -> {:json, json}
      {:error, _} -> rendered_body # Assumed text/plain
    end
  end
end
