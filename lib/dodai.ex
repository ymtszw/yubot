defmodule Yubot.Dodai do
  @default_group_id (case SolomonLib.Env.compile_env() do
    :prod -> raise("Not ready!")
    :dev -> "g_9eTTqdNt"
    _local -> "g_MbhtDhFm"
  end)
  @test_group_id (case SolomonLib.Env.compile_env() do
    :prod -> raise("Not ready!")
    :dev -> "g_4xxYWNkn"
    _local -> "g_zCGtN44K"
  end)

  use SolomonAcs.Dodai.GearModule, app_id: "a_Eih41ySz", default_group_id: @default_group_id

  def app_key(),  do: Yubot.get_env("dodai_app_key")
  def root_key(), do: Yubot.get_env("dodai_root_key")

  def test_group_id(), do: @test_group_id
end
