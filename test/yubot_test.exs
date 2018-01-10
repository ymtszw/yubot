defmodule YubotTest do
  use ExUnit.Case, async: true

  test "should show Fib page" do
    %_res{status: 200, body: b} = Req.get("/fib")
    assert String.contains?(b, "Fib!")
  end
end
