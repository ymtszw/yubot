use Croma

defmodule Yubot.Dodai.Model.Users.Impl do
  @moduledoc false

  alias Croma.Result, as: R
  alias Dodai.{GroupId, Query}
  alias SolomonAcs.Dodai.Model

  defun insert(model             :: v[module],
               id_module         :: v[module],
               data_module       :: v[module],
               rootonly_module   :: v[module],
               readonly_module   :: v[module],
               client            :: Dodai.Client.t,
               raw_insert_action :: v[map],
               key               :: v[String.t],
               group_id          :: v[GroupId.t]) :: R.t(struct) do
    R.m do
      i_a0 <- ensure_identity_field(raw_insert_action)
      i_a1 <- validate_user_defined_fields(i_a0, id_module, data_module, rootonly_module, readonly_module)
      body <- Dodai.CreateUserRequestBody.new(i_a1)
      Dodai.Client.send(client, Dodai.CreateUserRequest.new(group_id, key, body)) |> Model.handle_api_response(model)
    end
  end

  defp ensure_identity_field(dict) do
    if dict[:email] || dict[:name], do: {:ok, dict}, else: {:error, [:value_missing, :email_or_name]}
  end

  defp validate_user_defined_fields(dict, id_module, data_module, rootonly_module, readonly_module) do
    dict
    |> Enum.map(fn
      {:_id, id}            -> id |> id_module.validate_on_insert() |> R.map(&{:_id, &1})
      {:data, data}         -> data |> data_module.new() |> R.map(&{:data, &1})
      {:rootonly, rootonly} -> rootonly |> rootonly_module.new() |> R.map(&{:rootonly, &1})
      {:readonly, readonly} -> readonly |> readonly_module.new() |> R.map(&{:readonly, &1})
      otherwise             -> {:ok, otherwise}
    end)
    |> R.sequence()
  end

  defun update(model             :: v[module],
               client            :: Dodai.Client.t,
               raw_update_action :: v[map],
               id                :: v[String.t],
               key               :: v[String.t],
               group_id          :: v[GroupId.t]) :: R.t(struct) do
    R.bind(Dodai.UpdateUserRequestBody.new(raw_update_action), fn body ->
      Dodai.Client.send(client, Dodai.UpdateUserRequest.new(group_id, id, key, body)) |> Model.handle_api_response(model)
    end)
  end

  defun delete(client   :: Dodai.Client.t,
               id       :: v[String.t],
               version  :: v[nil | non_neg_integer],
               key      :: v[String.t],
               group_id :: v[GroupId.t]) :: R.t(:no_content) do
    R.bind(Dodai.DeleteUserRequestQuery.new(%{version: version}), fn query ->
      Dodai.Client.send(client, Dodai.DeleteUserRequest.new(group_id, id, key, query)) |> Model.handle_api_response(nil)
    end)
  end

  defun retrieve(model    :: v[module],
                 client   :: Dodai.Client.t,
                 id       :: v[String.t],
                 key      :: v[String.t],
                 group_id :: v[GroupId.t]) :: R.t(struct) do
    Dodai.Client.send(client, Dodai.RetrieveUserRequest.new(group_id, id, key)) |> Model.handle_api_response(model)
  end

  defun retrieve_list(model           :: v[module],
                      client          :: Dodai.Client.t,
                      raw_list_action :: v[map],
                      key             :: v[String.t],
                      group_id        :: v[GroupId.t]) :: R.t([struct]) do
    R.bind(Dodai.RetrieveUserListRequestQuery.new(raw_list_action), fn query ->
      Dodai.Client.send(client, Dodai.RetrieveUserListRequest.new(group_id, key, query)) |> Model.handle_api_response(model)
    end)
  end

  defun count(client    :: Dodai.Client.t,
              raw_query :: v[nil | Query.t],
              key       :: v[String.t],
              group_id  :: v[GroupId.t]) :: R.t(non_neg_integer) do
    R.bind(Dodai.CountUsersRequestQuery.new(%{query: raw_query}), fn query ->
      Dodai.Client.send(client, Dodai.CountUsersRequest.new(group_id, key, query)) |> Model.handle_api_response(nil)
    end)
  end

  # Users specific APIs

  defun update_auth_info(model              :: v[module],
                         client             :: Dodai.Client.t,
                         update_auth_action :: v[map],
                         id                 :: v[String.t],
                         key                :: v[String.t],
                         group_id           :: v[GroupId.t]) :: R.t(struct) do
    R.bind(Dodai.UpdateAuthInfoRequestBody.new(update_auth_action), fn body ->
      Dodai.Client.send(client, Dodai.UpdateAuthInfoRequest.new(group_id, id, key, body)) |> Model.handle_api_response(model)
    end)
  end

  defun login(model        :: v[module],
              client       :: Dodai.Client.t,
              login_action :: v[map],
              key          :: v[String.t],
              group_id     :: v[GroupId.t]) :: R.t(struct) do
    R.bind(Dodai.UserLoginRequestBody.new(login_action), fn body ->
      Dodai.Client.send(client, Dodai.UserLoginRequest.new(group_id, key, body)) |> Model.handle_api_response(model)
    end)
  end

  defun logout(client   :: Dodai.Client.t,
               key      :: v[String.t],
               group_id :: v[GroupId.t]) :: R.t(struct) do
    Dodai.Client.send(client, Dodai.UserLogoutRequest.new(group_id, key)) |> Model.handle_api_response(nil)
  end

  defun retrieve_self(model    :: v[module],
                      client   :: Dodai.Client.t,
                      key      :: v[String.t],
                      group_id :: v[GroupId.t]) :: R.t(struct) do
    Dodai.Client.send(client, Dodai.RetrieveSelfUserRequest.new(group_id, key)) |> Model.handle_api_response(model)
  end
end
