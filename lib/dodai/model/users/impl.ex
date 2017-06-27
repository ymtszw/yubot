use Croma

defmodule Yubot.Dodai.Model.Users.Impl do
  @moduledoc false

  alias Croma.Result, as: R
  alias Dodai.GroupId
  alias SolomonAcs.Dodai.{Model, Query}

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
      i_a <- ensure_identity_field(raw_insert_action)
      body <- validate_user_defined_fields(i_a, model, id_module, data_module, rootonly_module, readonly_module)
      Dodai.Client.send(client, Dodai.CreateUserRequest.new(group_id, key, body))
      |> Model.handle_api_response(model)
    end
  end

  defp ensure_identity_field(dict) do
    if dict[:email] || dict[:name], do: {:ok, dict}, else: {:error, [:value_missing, :email_or_name]}
  end

  defp validate_user_defined_fields(dict, model, id_module, data_module, rootonly_module, readonly_module) do
    dict
    |> Enum.map(fn
      {:_id, id}            -> id |> id_module.validate_on_insert() |> R.map(&{:_id, &1})
      {:data, data}         -> data |> data_module.new() |> R.map(&{:data, &1})
      {:rootonly, rootonly} -> rootonly |> rootonly_module.new() |> R.map(&{:rootonly, &1})
      {:readonly, readonly} -> readonly |> readonly_module.new() |> R.map(&{:readonly, &1})
      otherwise             -> {:ok, otherwise}
    end)
    |> R.sequence()
    |> R.bind(&Dodai.CreateUserRequestBody.new/1)
    |> set_model_module_field(model)
  end

  defp set_model_module_field({:ok, %Dodai.CreateUserRequestBody{data: nil} = body}, model) do
    {:ok, put_in(body.data, %{_model_module: inspect(model)})}
  end
  defp set_model_module_field({:ok, %Dodai.CreateUserRequestBody{data: %_data_struct{}} = body}, model) do
    {:ok, update_in(body.data, fn data -> data |> Map.from_struct() |> Map.put(:_model_module, inspect(model)) end)}
  end
  defp set_model_module_field({:error, _} = e, _model), do: e

  defun update(model             :: v[module],
               client            :: Dodai.Client.t,
               raw_update_action :: v[map],
               id                :: v[String.t],
               key               :: v[String.t],
               group_id          :: v[GroupId.t]) :: R.t(struct) do
    raw_update_action
    |> ensure_model_module_field(model)
    |> Dodai.UpdateUserRequestBody.new()
    |> R.bind(fn body ->
      Dodai.Client.send(client, Dodai.UpdateUserRequest.new(group_id, id, key, body)) |> Model.handle_api_response(model)
    end)
  end

  defp ensure_model_module_field(raw_update_action, model) do
    Map.new(raw_update_action, fn
      {:data, data_update} -> {:data, ensure_model_module_field_impl(data_update, model)}
      otherwise            -> otherwise
    end)
  end

  defp ensure_model_module_field_impl(nil        , _model), do: nil # will be dropped by dodai_client_elixir
  defp ensure_model_module_field_impl(data_update,  model) when is_map(data_update) do
    partial_update_operator? = fn {key, _val} -> String.starts_with?(key, "$") end
    if Enum.any?(data_update, partial_update_operator?) do
      data_update
    else
      Map.put(data_update, :_model_module, inspect(model))
    end
  end

  defun delete(client   :: Dodai.Client.t,
               id       :: v[String.t],
               version  :: v[nil | non_neg_integer],
               key      :: v[String.t],
               group_id :: v[GroupId.t]) :: R.t(:no_content) do
    Dodai.Client.send(client, Dodai.DeleteUserRequest.new(group_id, id, key, %Dodai.DeleteUserRequestQuery{version: version}))
    |> Model.handle_api_response(nil)
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
    R.m do
      l_a0 <- list_action_with_model_module_query(raw_list_action, model)
      l_a1 <- Model.ListAction.new(l_a0)
      query = struct(Dodai.RetrieveUserListRequestQuery, Map.from_struct(l_a1))
      Dodai.Client.send(client, Dodai.RetrieveUserListRequest.new(group_id, key, query))
      |> Model.handle_api_response(model)
    end
  end

  defp list_action_with_model_module_query(%{query: query_dict} = l_a, model) when is_map(query_dict) or is_list(query_dict) do
    {:ok, put_in(l_a[:query]["data._model_module"], inspect(model))}
  end
  defp list_action_with_model_module_query(l_a, model) when is_map(l_a) do
    {:ok, put_in(l_a[:query], %{"data._model_module" => inspect(model)})}
  end
  defp list_action_with_model_module_query(_invalid_list_action, _model) do
    {:error, {:invalid_value, [Croma.Map]}}
  end

  defun count(model     :: v[module],
              client    :: Dodai.Client.t,
              raw_query :: v[nil | Query.t],
              key       :: v[String.t],
              group_id  :: v[GroupId.t]) :: R.t(non_neg_integer) do
    query = %Dodai.CountUsersRequestQuery{query: model_module_query(raw_query, model)}
    Dodai.Client.send(client, Dodai.CountUsersRequest.new(group_id, key, query))
    |> Model.handle_api_response(nil)
  end

  defp model_module_query(nil, model), do: %{"data._model_module" => inspect(model)}
  defp model_module_query(raw_query, model), do: put_in(raw_query["data._model_module"], inspect(model))

  # Users specific APIs

  defun update_auth_info(model              :: v[module],
                         client             :: Dodai.Client.t,
                         update_auth_action :: v[map],
                         id                 :: v[String.t],
                         key                :: v[String.t],
                         group_id           :: v[GroupId.t]) :: R.t(struct) do
    update_auth_action
    |> Dodai.UpdateAuthInfoRequestBody.new()
    |> R.bind(fn body ->
      Dodai.Client.send(client, Dodai.UpdateAuthInfoRequest.new(group_id, id, key, body)) |> Model.handle_api_response(model)
    end)
  end

  defun login(model        :: v[module],
              client       :: Dodai.Client.t,
              login_action :: v[map],
              key          :: v[String.t],
              group_id     :: v[GroupId.t]) :: R.t(struct) do
    login_action
    |> Dodai.UserLoginRequestBody.new()
    |> R.bind(fn body ->
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
