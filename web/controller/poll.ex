use Croma

defmodule Yubot.Controller.Poll do
  alias Croma.Result, as: R
  alias SolomonLib.Cron
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.External.Http, as: ExHttp
  alias Yubot.Model.{Poll, Action, Authentication}
  alias Yubot.Model.Poll.TrialRequest, as: TryReq
  alias Yubot.Service.RunPoll

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
    R.m do
      data <- Poll.Data.new(conn.request.body)
      user_editable_data = data |> Map.from_struct() |> Map.drop([:last_run_at, :next_run_at, :history])
      updated_poll <- Poll.update(%{data: %{"$set" => user_editable_data}}, conn.request.path_matches.id, key(conn), group_id(conn))
      update_next_run_at(updated_poll, conn)
    end
    |> handle_with_200_json(conn)
  end

  defp update_next_run_at(%Poll{_id: id, data: %Poll.Data{interval: i, last_run_at: lra, next_run_at: nra}} = poll, conn) do
    case i |> Poll.Interval.to_cron(id) |> Cron.parse!() |> Cron.next(lra) do
      ^nra        -> {:ok, poll}
      updated_nra -> Poll.set_run_at(updated_nra, lra, id, key(conn), group_id(conn))
    end
  end

  # DELETE /api/poll/:id
  def delete(conn) do
    Poll.delete(conn.request.path_matches.id, nil, key(conn), group_id(conn))
    |> handle_with_204(conn)
  end

  # POST /api/poll/try
  def try(conn) do
    R.m do
      _conn <- reject_on_rate_limit(conn)
      %TryReq{url: u, auth_id: nil_or_auth_id} <- TryReq.new(conn.request.body)
      nil_or_auth <- fetch_auth(nil_or_auth_id, conn)
      ExHttp.request(:get, u, "", nil_or_auth)
    end
    |> handle_with_200_json(conn)
  end

  defp fetch_auth(nil, _conn), do: {:ok, nil}
  defp fetch_auth(auth_id, conn), do: Authentication.retrieve(auth_id, key(conn), group_id(conn))

  # POST /api/poll/run
  def run(conn) do
    R.m do
      _conn <- reject_on_rate_limit(conn)
      %Poll.Data{} = data <- Poll.Data.new(conn.request.body)
      exec_result <- RunPoll.exec(data, key(conn), group_id(conn), true)
      Poll.HistoryEntry.from_tuple(exec_result, conn.context.start_time)
    end
    |> handle_with_200_json(conn)
  end
end
