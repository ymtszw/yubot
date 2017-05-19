use Croma

defmodule Yubot.Controller.Action do
  alias Croma.Result, as: R
  use Yubot.Controller
  alias Yubot.Model.{Action, Authentication}

  # POSt /api/action
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
    Authentication.retrieve(auth_id, key)
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

  # DELETE /api/action/:id
  def delete(conn) do
    Action.delete(conn.request.path_matches.id, nil, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_204(conn)
  end
end
