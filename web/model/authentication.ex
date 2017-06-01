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
  alias SolomonLib.Crypto.Aes

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
    put_in(data["token"], encrypt(raw_token))
  end
  defp encrypt_token(%{token: raw_token} = data) do
    put_in(data[:token], encrypt(raw_token))
  end

  defp encrypt(raw_token) do
    Aes.ctr128_encrypt(raw_token, Yubot.get_env("encryption_key")) |> Base.encode64()
  end

  defun decrypt_token(%__MODULE__{data: %Data{token: encrypted_token}} = auth) :: R.t(t) do
    decrypt(encrypted_token)
    |> R.map(fn decrypted_token -> put_in(auth.data.token, decrypted_token) end)
  end

  defp decrypt(encrypted_token) do
    case Base.decode64(encrypted_token) do
      {:ok, encrypted_binary} -> Aes.ctr128_decrypt(encrypted_binary, Yubot.get_env("encryption_key"))
      :error                  -> {:ok, encrypted_token} # Fallback for old data; not encrypted
    end
  end
end
