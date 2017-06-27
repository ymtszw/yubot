use Croma

defmodule Yubot.Model.Authentication do
  @moduledoc """
  Authentication object for both polling endpoint and HTTP action target endpoint.

  ## Types

  - `:raw` - Put `:token` value in "Authorization" header as is, on request.
  - `:bearer` - Put `:token` value in "Authorization" header as "Bearer <token_value>" on request.
  - `:hipchat` - Same as `:bearer`. Require notification_token or token with broader scope granted.
  """

  alias Croma.Result, as: R

  defmodule Name do
    use Croma.SubtypeOfString, pattern: ~r/\A.+\Z/
  end

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [:raw, :bearer, :hipchat]
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    name: Name,
    type: Type,
    token: Croma.String,
  ]

  defun encrypt_token_and_insert(%{data: data} = i_a :: insert_action_t, key :: v[String.t], group_id :: v[Dodai.GroupId.t]) :: R.t(t) do
    insert(put_in(i_a.data, encrypt_token(data)), key, group_id)
  end

  defp encrypt_token(%{"token" => raw_token} = data) do
    put_in(data["token"], Yubot.encrypt_base64(raw_token))
  end
  defp encrypt_token(%{token: raw_token} = data) do
    put_in(data[:token], Yubot.encrypt_base64(raw_token))
  end

  defun decrypt_token(%__MODULE__{data: %Data{token: base64_token}} = auth) :: R.t(t) do
    Yubot.decrypt_base64(base64_token)
    |> R.map(fn decrypted_token -> put_in(auth.data.token, decrypted_token) end)
  end

  defun header(nil_or_auth :: nil | %__MODULE__{}) :: R.t(%{String.t => String.t}) do
    (nil) ->
      {:ok, %{}}
    (%__MODULE__{data: %Data{type: type, token: base64_token}}) ->
      base64_token |> Yubot.decrypt_base64() |> R.map(&%{"authorization" => header_impl(type, &1)})
  end

  defp header_impl(:raw, token), do: token
  defp header_impl(type, token) when type in [:bearer, :hipchat], do: "Bearer #{token}"
end
