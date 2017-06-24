use Croma

defmodule Yubot.Model.Action do
  @moduledoc """
  HTTP action object.
  """

  alias SolomonLib.Httpc
  alias Yubot.StringTemplate, as: ST
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

  def try(%TrialRequest{data: %Data{method: m, url: u, body_template: b}, trial_values: tv}, nil_or_auth) do
    Croma.Result.m do
      rendered_body <- ST.render(b, tv)
      auth_header <- Authentication.header(nil_or_auth)
      {elapsed_us, result} = :timer.tc(Httpc, :request, [m, u, httpc_body(rendered_body), auth_header, []])
      result
      |> httpc_result_to_map()
      |> Map.put(:elapsed_ms, elapsed_us / 1_000)
    end
  end

  defp httpc_body(""), do: ""
  defp httpc_body(rendered_body) do
    case Poison.decode(rendered_body) do
      {:ok, json} -> {:json, json}
      {:error, _} -> rendered_body # Assumed text/plain
    end
  end

  defp httpc_result_to_map({:ok, httpc_response}), do: Map.from_struct(httpc_response)
  defp httpc_result_to_map({:error, error}) do
    %{body: "Error on action trial: #{inspect(error)}", headers: %{}, status: 500} # Pseudo-Httpc.Response
  end
end
