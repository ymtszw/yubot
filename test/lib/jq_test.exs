defmodule Yubot.JqTest do
  use Croma.TestCase

  test "should run jq filter against map or JSON string" do
    assert Jq.run(%{foo: 1, bar: 2}        , ~S({foo})) == {:ok, ~S({"foo":1})}
    assert Jq.run(%{"foo" => 1, "bar" => 2}, ~S({foo})) == {:ok, ~S({"foo":1})}
    assert Jq.run(~S({"foo":1,"bar":2})    , ~S({foo})) == {:ok, ~S({"foo":1})}

    {:ok, result} = Jq.run(%{foo: 1, bar: 2}, ~S({foo}), pretty: true)
    assert result == """
    {
      "foo": 1
    }
    """
  end

  test "should invalidate invalid parameters" do
    assert_raise(RuntimeError, fn -> Jq.run(%{hoge: 1}, "{" <> String.duplicate("hoge", 1024) <> "}") end)
    assert Jq.run(%{hoge: 1}, "foo") == {:error, "jq: error: foo/0 is not defined at <top-level>, line 1:\nfoo\njq: 1 compile error\n"}
  end
end
