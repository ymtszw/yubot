use Croma

defmodule Yubot.Controller.Action do
  alias Croma.Result, as: R
  use Yubot.Controller
  alias Yubot.RateLimiter
  alias Yubot.Model.{Action, Authentication}

  # POST /api/action
  def create(conn) do
    create_impl(conn.request.body, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_201_json(conn)
  end

  defp create_impl(%{"auth" => create_auth_body} = body, key, group_id) when is_map(create_auth_body) do
    Authentication.encrypt_token_and_insert(%{data: create_auth_body}, key, group_id)
    |> R.bind(fn %Authentication{_id: auth_id} ->
      Action.insert(%{data: %{body | "auth" => auth_id}}, key, group_id)
    end)
  end
  defp create_impl(%{"auth" => auth_id} = body, key, group_id) when is_binary(auth_id) do
    Authentication.retrieve(auth_id, key, group_id)
    |> R.bind(fn %Authentication{} -> Action.insert(%{data: body}, key, group_id) end)
  end
  defp create_impl(body, key, group_id) do
    Action.insert(%{data: body}, key, group_id)
  end

  # GET /api/action/:id
  def retrieve(conn) do
    Action.retrieve(conn.request.path_matches.id, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # GET /api/action
  def retrieve_list(conn) do
    Action.retrieve_list(%{}, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # PUT /api/action
  def update(conn) do
    Action.Data.new(conn.request.body)
    |> R.bind(&update_impl(&1, conn.request.path_matches.id, Yubot.Dodai.root_key(), group_id(conn)))
    |> handle_with_200_json(conn)
  end

  defp update_impl(%{auth: auth_id} = update_data, id, key, group_id) when is_binary(auth_id) do
    Authentication.retrieve(auth_id, key, group_id)
    |> R.bind(fn %Authentication{} -> Action.update(%{data: update_data}, id, key, group_id) end)
  end
  defp update_impl(update_data, id, key, group_id) do
    Action.update(%{data: update_data}, id, key, group_id)
  end

  # DELETE /api/action/:id
  def delete(conn) do
    Action.delete(conn.request.path_matches.id, nil, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_204(conn)
  end

  # POST /api/action/try
  def try(conn) do
    R.m do
      _conn <- reject_on_rate_limit(conn)
      trial_request <- Action.TrialRequest.new(conn.request.body)
      nil_or_auth   <- fetch_auth(trial_request.data.auth, conn)
      pure Action.try(trial_request, nil_or_auth)
    end
    |> handle_with_200_json(conn)
  end

  defp reject_on_rate_limit(conn) do
    if try_call_limit_reached?(conn.request.sender) do
      {:error, {:too_many_requests, "Too many requests. Try again later."}}
    else
      {:ok, conn}
    end
  end

  defp try_call_limit_reached?(sender) do
    RateLimiter.push(sender, [{5, 5_000}, {20, 60_000}])
  end

  defp fetch_auth(nil, _conn), do: {:ok, nil}
  defp fetch_auth(auth_id, conn), do: Authentication.retrieve(auth_id, Yubot.Dodai.root_key(), group_id(conn))
end
