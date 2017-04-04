use Croma

defmodule Yubot.Model.Authentication do
  @moduledoc """
  Authentication object for both polling endpoint and action target endpoint.
  """

  alias Croma.Result, as: R
  alias SolomonLib.Crypto.Aes

  defmodule Name do
    use Croma.SubtypeOfString, pattern: ~r/\A.+\Z/
  end

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [:raw, :bearer]
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

  defun retrieve_and_decrypt_token(id :: v[Id.t], key :: v[String.t], group_id :: v[Dodai.GroupId.t]) :: R.t(String.t) do
    R.m do
      %__MODULE__{data: %Data{token: encrypted_token}} = auth <- retrieve(id, key, group_id)
      raw_token <- decrypt(encrypted_token)
      pure put_in(auth.data.token, raw_token)
    end
  end

  def decrypt(encrypted_token) do
    Base.decode64(encrypted_token) |> R.bind(&Aes.ctr128_decrypt(&1, Yubot.get_env("encryption_key")))
  end
end
