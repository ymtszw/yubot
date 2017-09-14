defmodule Yubot.Repo.Users do
  use SolomonAcs.Dodai.Repo.Users, client_config: %{recv_timeout: 10_000}, user_models: [Yubot.Model.User]
end
