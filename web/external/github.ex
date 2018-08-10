use Croma

defmodule Yubot.External.Github do
  @moduledoc """
  Binding for GitHub Users API.
  """

  alias Croma.Result, as: R
  alias Antikythera.Httpc

  @base_url "https://api.github.com"

  defun retrieve_self(token :: v[String.t]) :: R.t({String.t, String.t}) do
    R.m do
      header = %{"authorization" => "Bearer #{token}"}
      {email_or_nil, name} <- retrieve_authenticated_user(header)
      if email_or_nil do
        {:ok, {email_or_nil, name}}
      else
        retrieve_primary_email(header) |> R.map(fn primary_email -> {primary_email, name} end)
      end
    end
  end

  defp retrieve_authenticated_user(header) do
    Httpc.get(@base_url <> "/user", header)
    |> handle_github_response(fn user_object ->
      %{"login" => login_name, "name" => display_name, "email" => email_or_nil, "avatar_url" => _} = user_object
      # Now (as of 2018/08) it seems users without "publicly visible email" set will get nil in "email" field
      {:ok, {email_or_nil, display_name || login_name}}
    end)
  end

  defp retrieve_primary_email(header) do
    Httpc.get(@base_url <> "/user/emails", header)
    |> handle_github_response(fn email_objects ->
      primary_email = email_objects |> Enum.find_value(fn email_object -> email_object["primary"] && email_object end) |> Map.get("email")
      {:ok, primary_email}
    end)
  end

  defp handle_github_response(httpc_res, success_fun) do
    case httpc_res do
      {:ok, %Httpc.Response{status: 200, body: res_body}} ->
        success_fun.(Poison.decode!(res_body))
      {:ok, %Httpc.Response{status: code, body: res_body}} ->
        {:error, {code, res_body}}
      error ->
        error
    end
  end
end
