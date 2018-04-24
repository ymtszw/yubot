use Croma

defmodule Yubot.Controller.Action do
  alias Croma.Result, as: R
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.Repo.Action, as: RAc
  alias Yubot.Model.Action

  # POST /api/action
  def create(conn) do
    RAc.insert(%{data: conn.request.body}, Util.key(conn), Util.group_id(conn))
    |> Result.handle_with_201_json(conn)
  end

  # GET /api/action/:id
  def retrieve(conn) do
    RAc.retrieve(conn.request.path_matches.id, Util.key(conn), Util.group_id(conn))
    |> Result.handle_with_200_json(conn)
  end

  # GET /api/action
  def retrieve_list(conn) do
    RAc.retrieve_list(%{}, Util.key(conn), Util.group_id(conn))
    |> Result.handle_with_200_json(conn)
  end

  # PUT /api/action
  def update(conn) do
    Action.Data.new(conn.request.body)
    |> R.bind(&RAc.update(%{data: &1}, conn.request.path_matches.id, Util.key(conn), Util.group_id(conn)))
    |> Result.handle_with_200_json(conn)
  end

  # DELETE /api/action/:id
  def delete(conn) do
    RAc.delete(conn.request.path_matches.id, nil, Util.key(conn), Util.group_id(conn))
    |> Result.handle_with_204(conn)
  end

  # POST /api/action/try
  def try(conn) do
    R.m do
      _conn <- Util.reject_on_rate_limit(conn)
      trial_request <- Action.TrialRequest.new(conn.request.body)
      nil_or_auth <- fetch_auth(trial_request.data.auth_id, conn)
      Action.exec(trial_request, nil_or_auth)
    end
    |> Result.handle_with_200_json(conn)
  end

  defp fetch_auth(nil, _conn), do: {:ok, nil}
  defp fetch_auth(auth_id, conn), do: Yubot.Repo.Authentication.retrieve(auth_id, Util.key(conn), Util.group_id(conn))
end
