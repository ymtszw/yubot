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
    # auth: Croma.TypeGen.nilable(Authentication.Id), # DEPRECATED; Eliminating since nilable field cannot be distinguished its version by itself
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
  Actually try an Action execution with `:trial_values` as material.

  It also record elapsed time for the Action.
  """
  def try(%TrialRequest{data: %Data{method: m, url: u, body_template: b}, trial_values: tv}, nil_or_auth) do
    ST.render(b, tv)
    |> Croma.Result.bind(&ExHttp.request(m, u, httpc_body(&1), nil_or_auth))
  end

  defp httpc_body(""), do: ""
  defp httpc_body(rendered_body) do
    case Poison.decode(rendered_body) do
      {:ok, json} -> {:json, json}
      {:error, _} -> rendered_body # Assumed text/plain
    end
  end

  # Convenient APIs

  @doc """
  Retrieve by `_id`s, and also ensure all of them existed.

  If some of them are not existed, it results in error with list of not found `_id`s.

  Used on both creation and execution.
  """
  @spec retrieve_list_and_ensure_by_ids([Id.t], String.t, Dodai.GroupId.t) :: R.t([t])
  def retrieve_list_and_ensure_by_ids([], _key, _group_id) do
    {:ok, []}
  end
  def retrieve_list_and_ensure_by_ids(ids, key, group_id) do
    case retrieve_list(%{query: %{_id: %{"$in" => ids}}}, key, group_id) do
      {:ok, as} when length(as) == length(ids) ->
        {:ok, as}
      {:ok, as} ->
        non_existing_ids = ids -- Enum.map(as, &(&1._id))
        {:error, {:not_found, "Actions not found: #{Enum.join(non_existing_ids, ", ")}"}}
      error ->
        error
    end
  end
end
