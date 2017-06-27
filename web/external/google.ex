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
      %Httpc.Response{status: 200, body: res_body} <- Httpc.get(@people_api_url <> "/people/me", header, params: params)
      body <- Poison.decode(res_body)
      pure retrieve_self_response(body)
    end
  end

  defp retrieve_self_response(%{"names" => names, "emailAddresses" => emails, "photos" => _}) do
    email = Enum.find(emails, fn email -> email["metadata"]["primary"] end)["value"]
    display_name = Enum.find(names, fn name -> name["metadata"]["primary"] end)["displayName"]
    {email, display_name}
  end
end
