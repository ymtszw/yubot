use Croma

defmodule Yubot.Repo.Authentication do
  alias AntikytheraAcs.Dodai.Repo.Datastore, as: RD
  alias Yubot.Model.Authentication, as: MA
  use RD, datastore_models: [MA]

  defun encrypt_token_and_insert(%{data: data} = i_a :: RD.insert_action_t, key :: v[String.t], group_id :: v[Dodai.GroupId.t]) :: R.t(MA.t) do
    insert(put_in(i_a.data, encrypt_token(data)), key, group_id)
  end

  defp encrypt_token(%{"token" => raw_token} = data) do
    put_in(data["token"], Yubot.encrypt_base64(raw_token))
  end
  defp encrypt_token(%{token: raw_token} = data) do
    put_in(data[:token], Yubot.encrypt_base64(raw_token))
  end
end
