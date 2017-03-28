defmodule Yubot.Dodai do
  use SolomonAcs.Dodai.GearModule, app_id: "a_Eih41ySz", default_group_id: "g_MbhtDhFm"

  def app_key(),  do: Yubot.get_env("dodai_app_key")
  def root_key(), do: Yubot.get_env("dodai_root_key")
end
