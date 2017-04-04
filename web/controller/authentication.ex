use Croma

defmodule Yubot.Controller.Authentication do
  use Yubot.Controller
  alias Yubot.Model.Authentication

  # POST /api/authentication
  def create(conn) do
    Authentication.encrypt_token_and_insert(%{data: conn.request.body}, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_201_json(conn)
  end

  # GET /api/authentication/:id
  def retrieve(conn) do
    Authentication.retrieve_and_decrypt_token(conn.request.path_matches.id, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_200_json(conn)
  end

  # GET /api/authentication
  def retrieve_list(conn) do
    Authentication.retrieve_list(%{}, Yubot.Dodai.root_key(), group_id(conn))
    |> handle_with_200_json(conn)
  end
end
