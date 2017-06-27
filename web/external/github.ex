use Croma

defmodule Yubot.External.Github do
  @moduledoc """
  Binding for GitHub Users API.
  """

  alias Croma.Result, as: R
  alias SolomonLib.Httpc

  @base_url "https://api.github.com"

  defun retrieve_self(token :: v[String.t]) :: R.t({String.t, String.t}) do
    R.m do
      header = %{"authorization" => "Bearer #{token}"}
      %Httpc.Response{status: 200, body: res_body} <- Httpc.get(@base_url <> "/user", header)
      body <- Poison.decode(res_body)
      pure retrieve_self_response(body)
    end
  end

  defp retrieve_self_response(%{"name" => display_name, "email" => email, "avatar_url" => _}) do
    {email, display_name}
  end
end
