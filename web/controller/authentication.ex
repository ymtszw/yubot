use Croma

defmodule Yubot.Controller.Authentication do
  alias Croma.Result, as: R
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.Repo.Authentication, as: RAu
  alias Yubot.Model.Authentication

  # POST /api/authentication
  def create(conn) do
    RAu.encrypt_token_and_insert(%{data: conn.request.body}, Util.key(conn), Util.group_id(conn))
    |> R.bind(&Authentication.decrypt_token/1)
    |> Result.handle_with_201_json(conn)
  end

  # GET /api/authentication/:id
  def retrieve(conn) do
    RAu.retrieve(conn.request.path_matches.id, Util.key(conn), Util.group_id(conn))
    |> R.bind(&Authentication.decrypt_token/1)
    |> Result.handle_with_200_json(conn)
  end

  # GET /api/authentication
  def retrieve_list(conn) do
    RAu.retrieve_list(%{}, Util.key(conn), Util.group_id(conn))
    |> R.bind(fn auths -> Enum.map(auths, &Authentication.decrypt_token/1) |> R.sequence() end)
    |> Result.handle_with_200_json(conn)
  end

  # DELETE /api/authentication/:id
  def delete(conn) do
    RAu.delete(conn.request.path_matches.id, nil, Util.key(conn), Util.group_id(conn))
    |> Result.handle_with_204(conn)
  end
end
