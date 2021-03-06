Antikythera.Test.Config.init

defmodule Req do
  use Antikythera.Test.HttpClient

  @bb_headers %{"x-yubot-blackbox" => "true", "authorization" => "dummy_key"}

  def bb_post_json(path, body, headers \\ %{}), do: post_json(path, body, Map.merge(headers, @bb_headers))

  def bb_get(path, headers \\ %{}), do: get(path, Map.merge(headers, @bb_headers))
end

defmodule Socket do
  use Antikythera.Test.WebsocketClient
end

if Antikythera.Test.Config.blackbox_test?() do
  defmodule Yubot.Blackbox.Cleanup do
    alias Yubot.Model.{Poll, Action, Authentication}

    @test_group_id (case Antikythera.Test.Config.test_mode() do
      :blackbox_prod -> raise("Not ready!")
      :blackbox_dev -> "g_4xxYWNkn"
      :blackbox_local -> "g_zCGtN44K"
    end)

    def run() do
      root_key = Antikythera.Test.Config.blackbox_test_secret()["dodai_root_key"]
      {:ok, polls} = Poll.retrieve_list(%{}, root_key, @test_group_id)
      Enum.each(polls, fn %Poll{_id: poll_id} -> Poll.delete(poll_id, nil, root_key, @test_group_id) end)
      {:ok, actions} = Action.retrieve_list(%{}, root_key, @test_group_id)
      Enum.each(actions, fn %Action{_id: action_id} -> Action.delete(action_id, nil, root_key, @test_group_id) end)
      {:ok, auths} = Authentication.retrieve_list(%{}, root_key, @test_group_id)
      Enum.each(auths, fn %Authentication{_id: auth_id} -> Authentication.delete(auth_id, nil, root_key, @test_group_id) end)
    end
  end
end
