use Croma

defmodule Yubot.Controller.Poll do
  alias Croma.Result, as: R
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.StringTemplate, as: ST
  alias Yubot.Model.{Poll, Action, Authentication}

  # POST /api/poll
  def create(conn) do
    create_impl(conn.request.body, key(conn), group_id(conn))
    |> handle_with_201_json(conn)
  end

  defp create_impl(%{"auth" => auth, "action" => action} = body, key, group_id)
      when (is_map(action) or is_binary(action)) and (is_map(auth) or is_binary(auth)) do
    R.m do
      %Authentication{_id: auth_id} <- ensure_authentication(auth, key, group_id)
      %Action{_id: action_id, data: %Action.Data{body_template: %ST{variables: variables}}} <- ensure_action(action, key, group_id)
      validate_filter_length_and_insert_poll(variables, %{body | "auth" => auth_id, "action" => action_id}, key, group_id)
    end
  end
  defp create_impl(%{"action" => action} = body, key, group_id)
      when is_map(action) or is_binary(action) do
    ensure_action(action, key, group_id)
    |> R.bind(fn %Action{_id: action_id, data: %Action.Data{body_template: %ST{variables: variables}}} ->
      validate_filter_length_and_insert_poll(variables, %{body | "action" => action_id}, key, group_id)
    end)
  end

  defp validate_filter_length_and_insert_poll(variables, %{"filters" => filters} = body, key, group_id)
      when length(variables) == length(filters) do
    Poll.insert(%{data: body}, key, group_id)
  end
  defp validate_filter_length_and_insert_poll(variables, body, _key, _group_id) do
    bad_request([variables, body])
  end

  defp ensure_action(%{"auth" => auth} = body, key, group_id) when is_map(auth) or is_binary(auth) do
    ensure_authentication(auth, key, group_id)
    |> R.bind(fn %Authentication{_id: auth_id} -> Action.insert(%{data: %{body | "auth" => auth_id}}, key, group_id) end)
  end
  defp ensure_action(action_id, key, group_id) when is_binary(action_id) do
    Action.retrieve(action_id, key, group_id)
  end
  defp ensure_action(body, key, group_id) do
    Action.insert(%{data: body}, key, group_id)
  end

  defp ensure_authentication(create_auth_body, key, group_id) when is_map(create_auth_body) do
    Authentication.encrypt_token_and_insert(%{data: create_auth_body}, key, group_id)
  end
  defp ensure_authentication(auth_id, key, group_id) when is_binary(auth_id) do
    Authentication.retrieve(auth_id, key, group_id)
  end

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

  # DELETE /api/poll/:id
  def delete(conn) do
    Poll.delete(conn.request.path_matches.id, nil, key(conn), group_id(conn))
    |> handle_with_204(conn)
  end
end
