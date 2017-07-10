use Croma

defmodule Yubot.Controller.Poll do
  alias Croma.Result, as: R
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.External.Http, as: ExHttp
  alias Yubot.Model.{Poll, Action, Authentication}
  alias Yubot.Model.Poll.ShallowTrialRequest, as: ShallowReq

  # POST /api/poll
  def create(conn) do
    key = key(conn)
    group_id = group_id(conn)
    R.m do
      %Poll.Data{auth_id: nil_or_auth_id, triggers: triggers} = valid_body <- Poll.Data.new(conn.request.body)
      _auth_ensured <- ensure_authentication(nil_or_auth_id, key, group_id)
      _actions_ensured <- ensure_actions(triggers, key, group_id)
      Poll.insert(%{data: valid_body}, key, group_id)
    end
    |> handle_with_201_json(conn)
  end

  defp ensure_authentication(nil, _key, _group_id), do: {:ok, nil}
  defp ensure_authentication(aid, key, group_id), do: Authentication.retrieve(aid, key, group_id)

  defp ensure_actions([], _key, _group_id),
    do: {:ok, nil}
  defp ensure_actions(ts, key, group_id),
    do: ts |> Enum.map(&(&1.action_id)) |> Enum.uniq() |> Action.retrieve_list_and_ensure_by_ids(key, group_id)

  # GET /api/poll/:id
  def retrieve(conn) do
    Poll.retrieve(conn.request.path_matches.id, key(conn), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # GET /api/poll
  def retrieve_list(conn) do
    Poll.retrieve_list(%{}, key(conn), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # PUT /api/poll/:id
  def update(conn) do
    Poll.Data.new(conn.request.body)
    |> R.bind(&Poll.update(%{data: &1}, conn.request.path_matches.id, key(conn), group_id(conn)))
    |> handle_with_200_json(conn)
  end

  # DELETE /api/poll/:id
  def delete(conn) do
    Poll.delete(conn.request.path_matches.id, nil, key(conn), group_id(conn))
    |> handle_with_204(conn)
  end

  # POST /api/poll/shallow_try
  def shallow_try(conn) do
    R.m do
      _conn <- reject_on_rate_limit(conn)
      %ShallowReq{url: u, auth_id: nil_or_auth_id} <- ShallowReq.new(conn.request.body)
      nil_or_auth <- fetch_auth(nil_or_auth_id, conn)
      ExHttp.request(:get, u, "", nil_or_auth)
    end
    |> handle_with_200_json(conn)
  end

  defp fetch_auth(nil, _conn), do: {:ok, nil}
  defp fetch_auth(auth_id, conn), do: Authentication.retrieve(auth_id, key(conn), group_id(conn))
end
