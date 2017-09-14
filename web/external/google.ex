use Croma

defmodule Yubot.External.Google do
  @moduledoc """
  Binding for Google People API.
  """

  alias Croma.Result, as: R
  alias SolomonLib.Httpc

  @people_api_url "https://people.googleapis.com/v1"

  defun retrieve_self(token :: v[String.t]) :: R.t({String.t, String.t}) do
    R.m do
      header = %{"authorization" => "Bearer #{token}"}
      params = %{"requestMask.includeField" => "person.names,person.emailAddresses,person.photos"}
      response <- Httpc.get(@people_api_url <> "/people/me", header, params: params)
      retrieve_self_response(response)
    end
  end

  defp retrieve_self_response(%Httpc.Response{status: 200, body: res_body}) do
    %{"names" => names, "emailAddresses" => emails, "photos" => _} = Poison.decode!(res_body)
    email = Enum.find(emails, fn email -> email["metadata"]["primary"] end)["value"]
    display_name = Enum.find(names, fn name -> name["metadata"]["primary"] end)["displayName"]
    {:ok, {email, display_name}}
  end
  defp retrieve_self_response(%Httpc.Response{status: code, body: res_body}) do
    {:error, {code, res_body}}
  end
end
