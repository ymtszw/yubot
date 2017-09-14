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
      response <- Httpc.get(@base_url <> "/user", header)
      retrieve_self_response(response)
    end
  end

  defp retrieve_self_response(%Httpc.Response{status: 200, body: res_body}) do
    %{"login" => login_name, "name" => display_name, "email" => email, "avatar_url" => _} = Poison.decode!(res_body)
    {:ok, {email, display_name || login_name}}
  end
  defp retrieve_self_response(%Httpc.Response{status: code, body: res_body}) do
    {:error, {code, res_body}}
  end
end
