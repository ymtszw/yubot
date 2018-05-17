defmodule Yubot.Repo.Action do
  alias Yubot.Model.Action, as: MA
  use AntikytheraAcs.Dodai.Repo.Datastore, [
    datastore_models: [MA],
  ]

  @doc """
  Retrieve by `_id`s, and also ensure all of them existed.

  If some of them are not existed, it results in error with list of not found `_id`s.

  Used on both creation and execution.
  """
  @spec retrieve_list_and_ensure_by_ids([MA.Id.t], String.t, Dodai.GroupId.t) :: R.t([MA.t])
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
