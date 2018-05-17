defmodule Yubot.Dodai do
  @default_group_id (case Antikythera.Env.compile_env() do
    :prod -> raise("Not ready!")
    :dev -> "g_9eTTqdNt"
    _local -> "g_MbhtDhFm"
  end)
  use AntikytheraAcs.Dodai.GearModule,
    app_id: "a_Eih41ySz",
    default_group_id: @default_group_id,
    default_client_config: %{recv_timeout: 10_000}

  def app_key(),  do: Yubot.get_env("dodai_app_key")
  def root_key(), do: Yubot.get_env("dodai_root_key")

  @test_group_id (case Antikythera.Env.compile_env() do
    :prod -> raise("Not ready!")
    :dev -> "g_4xxYWNkn"
    _local -> "g_zCGtN44K"
  end)
  def test_group_id(), do: @test_group_id

  def app_id("prod"), do: raise("not ready!")
  def app_id(_dev_or_local), do: "a_Eih41ySz"

  def group_id("prod"), do: raise("not ready!")
  def group_id("dev"), do: "g_9eTTqdNt"
  def group_id(_local), do: "g_MbhtDhFm"
end
