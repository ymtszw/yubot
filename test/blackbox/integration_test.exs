defmodule Yubot.Blackbox.IntegrationTest do
  use ExUnit.Case
  alias SolomonLib.Httpc.Response, as: Res

  @moduletag :blackbox_only

  setup_all do
    on_exit(&Yubot.Blackbox.Cleanup.run/0)
  end

  test "POST /api/poll should create Poll and associated Action, Authentications" do
    %Res{status: 201, body: res_body0} = Req.bb_post_json("/api/poll", %{
      "interval" => "hourly",
      "url" => "https://poll.com",
      "auth" => %{
        "name" => "Poll Credential",
        "type" => "raw",
        "token" => "poll_credential",
      },
      "action" => %{
        "method" => "post",
        "url" => "https://target.com",
        "auth" => %{
          "name" => "Target Credential",
          "type" => "bearer",
          "token" => "target_credential",
        },
        "body_template" => %{
          "body" => ~S"""
          {
            "var": #{var}
          }
          """
        },
      },
      "filters" => [".var"]
    })
    body0 = Poison.decode!(res_body0)
    assert is_binary(body0["_id"])
    assert body0["data"]["interval"] == "hourly"
    assert body0["data"]["url"] == "https://poll.com"

    %Res{status: 200, body: res_body1} = Req.bb_get("/api/action/#{body0["data"]["action"]}")
    body1 = Poison.decode!(res_body1)
    assert body1["_id"] == body0["data"]["action"]
    assert body1["data"]["method"] == "post"
    assert body1["data"]["url"] == "https://target.com"
    assert body1["data"]["body_template"]["body"] == ~S"""
    {
      "var": #{var}
    }
    """
    assert body1["data"]["body_template"]["variables"] == ["var"]

    %Res{status: 200, body: res_body2} = Req.bb_get("/api/authentication/#{body0["data"]["auth"]}")
    body2 = Poison.decode!(res_body2)
    assert body2["_id"] == body0["data"]["auth"]
    assert body2["data"]["name"] == "Poll Credential"
    assert body2["data"]["type"] == "raw"
    assert body2["data"]["token"] == "poll_credential" # Decrypted

    %Res{status: 200, body: res_body3} = Req.bb_get("/api/authentication/#{body1["data"]["auth"]}")
    body3 = Poison.decode!(res_body3)
    assert body3["_id"] == body1["data"]["auth"]
    assert body3["data"]["name"] == "Target Credential"
    assert body3["data"]["type"] == "bearer"
    assert body3["data"]["token"] == "target_credential" # Decrypted
  end

  test "POST /api/action should create Action" do
    %Res{status: 201, body: res_body0} = Req.bb_post_json("/api/action", %{
      "method" => "post",
      "url" => "https://target.com",
      "auth" => %{
        "name" => "Target Credential",
        "type" => "bearer",
        "token" => "target_credential",
      },
      "body_template" => %{
        "body" => ~S"""
        {
          "var": #{var}
        }
        """
      },
    })
    body0 = Poison.decode!(res_body0)
    assert is_binary(body0["_id"])
    assert body0["data"]["body_template"]["body"] == ~S"""
    {
      "var": #{var}
    }
    """
    assert body0["data"]["body_template"]["variables"] == ["var"]

    %Res{status: 200, body: res_body1} = Req.bb_get("/api/authentication/#{body0["data"]["auth"]}")
    body1 = Poison.decode!(res_body1)
    assert body1["_id"] == body0["data"]["auth"]
    assert body1["data"]["name"] == "Target Credential"
    assert body1["data"]["type"] == "bearer"
    assert body1["data"]["token"] == "target_credential" # Decrypted
  end
end
