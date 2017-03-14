defmodule YubotTest do
  use ExUnit.Case

  test "should show static page" do
    %_res{status: 200, body: b} = Req.get("/static/fib.html")
    assert String.contains?(b, "Fib!")
  end
end
