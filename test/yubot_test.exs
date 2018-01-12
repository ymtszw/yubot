defmodule YubotTest do
  use ExUnit.Case, async: true

  test "should show index page" do
    %_res{status: 200, body: b} = Req.get("/")
    assert String.contains?(b, "Yubot Index")
  end

  test "should show template-generated page with Yubot.Asset.url/1 path" do
    %_res{status: 200, body: b0} = Req.get("/fib")
    assert String.contains?(b0, "Fib!")

    %_res{status: 200, body: b1} = Req.get("/poller")
    assert String.contains?(b1, "Poller the Bear")
  end
end
