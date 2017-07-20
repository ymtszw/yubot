use Croma

defmodule Yubot.External.Http do
  @moduledoc """
  Client module of external HTTP requests.

  Used in Poll/Action.
  """

  alias Croma.Result, as: R
  alias SolomonLib.{Httpc, Url}
  alias SolomonLib.Http.{Status, Method}
  alias Yubot.Model.Authentication, as: Auth

  @type response_t :: %{
    status: Status.t,
    headers: map,
    body: binary,
    body_hash: binary,
    elapsed_ms: float,
  }

  defun request(method :: v[Method.t], url :: v[Url.t], body :: v[Httpc.ReqBody.t], nil_or_auth :: v[nil | Auth.t]) :: R.t(response_t) do
    Auth.header(nil_or_auth)
    |> R.map(fn auth_header ->
      {elapsed_us, result} = :timer.tc(Httpc, :request, [method, url, body, auth_header, []])
      httpc_result_to_map(result, elapsed_us / 1_000) |> add_body_hash()
    end)
  end

  defp httpc_result_to_map({:ok, httpc_response}, elapsed_ms),
    do: httpc_response |> Map.from_struct() |> Map.put(:elapsed_ms, elapsed_ms)
  defp httpc_result_to_map({:error, error}, elapsed_ms),
    do: %{status: 500, headers: %{}, body: "Error on HTTP request: #{inspect(error)}", elapsed_ms: elapsed_ms}

  defp add_body_hash(%{body: b} = m), do: Map.put(m, :body_hash, :crypto.hash(:sha256, b) |> Base.encode64())
end
