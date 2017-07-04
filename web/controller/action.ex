use Croma

defmodule Yubot.Controller.Action do
  alias Croma.Result, as: R
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.Model.{Action, Authentication}

  # POST /api/action
  def create(conn) do
    Action.insert(%{data: conn.request.body}, key(conn), group_id(conn))
    |> handle_with_201_json(conn)
  end

  # GET /api/action/:id
  def retrieve(conn) do
    Action.retrieve(conn.request.path_matches.id, key(conn), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # GET /api/action
  def retrieve_list(conn) do
    Action.retrieve_list(%{}, key(conn), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # PUT /api/action
  def update(conn) do
    Action.Data.new(conn.request.body)
    |> R.bind(&Action.update(%{data: &1}, conn.request.path_matches.id, key(conn), group_id(conn)))
    |> handle_with_200_json(conn)
  end

  # DELETE /api/action/:id
  def delete(conn) do
    Action.delete(conn.request.path_matches.id, nil, key(conn), group_id(conn))
    |> handle_with_204(conn)
  end

  # POST /api/action/try
  def try(conn) do
    R.m do
      _conn <- reject_on_rate_limit(conn)
      trial_request <- Action.TrialRequest.new(conn.request.body)
      nil_or_auth <- fetch_auth(trial_request.data.auth_id, conn)
      Action.try(trial_request, nil_or_auth)
    end
    |> handle_with_200_json(conn)
  end

  defp fetch_auth(nil, _conn), do: {:ok, nil}
  defp fetch_auth(auth_id, conn), do: Authentication.retrieve(auth_id, key(conn), group_id(conn))
end
