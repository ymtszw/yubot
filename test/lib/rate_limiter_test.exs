defmodule Yubot.RateLimiterTest do
  use Croma.TestCase, alias_as: RL, async: true

  # Note: In MIX_ENV == test, expired limit entries are sweeped every 500ms

  test "should return boolean rate limit status" do
    refute RL.push({"web", "192.168.0.1"}, [{1, 1_000}])
    refute RL.push({"web", "192.168.0.2"}, [{3, 2_000}])
    assert RL.push({"web", "192.168.0.1"}, [{1, 1_000}]) # Locked
    refute RL.push({"web", "192.168.0.2"}, [{3, 2_000}])
    refute RL.push({"web", "192.168.0.2"}, [{3, 2_000}])
    assert RL.push({"web", "192.168.0.2"}, [{3, 2_000}]) # Locked
    :timer.sleep(500)
    assert RL.push({"web", "192.168.0.1"}, [{1, 1_000}]) # Still locked
    assert RL.push({"web", "192.168.0.2"}, [{3, 2_000}]) # Still locked
    :timer.sleep(501)
    refute RL.push({"web", "192.168.0.1"}, [{1, 1_000}]) # Unlocked
    assert RL.push({"web", "192.168.0.2"}, [{3, 2_000}]) # Still locked
    :timer.sleep(1_001)
    refute RL.push({"web", "192.168.0.1"}, [{1, 1_000}]) # Not locked again
    refute RL.push({"web", "192.168.0.2"}, [{3, 2_000}]) # Unlocked
    :timer.sleep(2_600)
    assert RL.get_state() == %{}
  end

  test "should rate limit by multiple limit unit" do
    refute RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}])
    refute RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}])
    refute RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}])
    assert RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}]) # Locked by 3/1_000 ms limit
    :timer.sleep(1_001)
    refute RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}]) # Unlocked since 3/1_000 limit is lifted
    assert RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}]) # Locked by 5/5_000 ms limit
    :timer.sleep(4_001)
    refute RL.push({"web", "192.168.0.3"}, [{3, 1_000}, {5, 5_000}]) # Unlocked since both limits are lifted
    :timer.sleep(5_600)
    assert RL.get_state() == %{}
  end
end
