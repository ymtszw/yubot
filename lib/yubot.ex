defmodule Yubot do
  use Antikythera.GearApplication
  alias Antikythera.{ExecutorPool, Conn, Crypto.Aes}

  @spec children :: [Supervisor.Spec.spec]
  def children() do
    dev_only_children() ++ [
      Yubot.RateLimiter.child_spec(),
    ]
  end

  if Mix.env == :dev do
    defp dev_only_children() do
      [
        Yubot.BigBoss.child_spec(),
        Yubot.LiveReload.child_spec(),
      ]
    end
  else
    defp dev_only_children(), do: []
  end

  @spec executor_pool_for_web_request(Conn.t) :: ExecutorPool.Id.t
  def executor_pool_for_web_request(_conn) do
    # specify executor pool to use; change the following line if your gear serves to multiple tenants
    {:gear, :yubot}
  end

  # Convenient APIs

  def encrypt_base64(plain_text) do
    plain_text |> Aes.ctr128_encrypt(get_env("encryption_key")) |> Base.encode64()
  end

  def decrypt_base64(base64_text) do
    case Base.decode64(base64_text) do
      {:ok, encrypted_binary} -> decrypt_impl(encrypted_binary, get_env("encryption_key"))
      :error -> {:error, {:invalid_value, :base64_string}}
    end
  end

  defp decrypt_impl(encrypted_binary, encryption_key) do
    case Aes.ctr128_decrypt(encrypted_binary, encryption_key) do
      {:ok, string} ->
        if String.printable?(string) do
          {:ok, string}
        else
          # This indicates the encryption_key differs from the one used on encryption
          {:error, {:internal_server_error, "A stored token cannot be decoded. Report to developers."}}
        end
      {:error, _} = e -> e
    end
  end
end
