use Croma

defmodule Yubot.Controller.Authentication do
  alias Croma.Result, as: R
  use Yubot.Controller
  alias Yubot.Model.Authentication

  # POST /api/authentication
  def create(conn) do
    Authentication.encrypt_token_and_insert(%{data: conn.request.body}, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_201_json(conn)
  end

  # GET /api/authentication/:id
  def retrieve(conn) do
    Authentication.retrieve(conn.request.path_matches.id, Yubot.Dodai.root_key(), group_id(conn))
    |> R.bind(&Authentication.decrypt_token/1)
    |> handle_with_200_json(conn)
  end

  # GET /api/authentication
  def retrieve_list(conn) do
    Authentication.retrieve_list(%{}, Yubot.Dodai.root_key(), group_id(conn))
    |> R.bind(fn auths -> Enum.map(auths, &Authentication.decrypt_token/1) |> R.sequence() end)
    |> handle_with_200_json(conn)
  end

  # DELETE /api/authentication/:id
  def delete(conn) do
    Authentication.delete(conn.request.path_matches.id, nil, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_204(conn)
  end
end
