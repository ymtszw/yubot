use Croma

defmodule Yubot.Controller.Grasp do
  alias Croma.Result, as: R
  use Yubot.Controller, auth: :cookie_or_header
  alias Yubot.Grasp

  # POST /api/grasp/try
  def try(conn) do
    R.m do
      %Grasp.TryRequest{source: s, instruction: i} <- Grasp.TryRequest.new(conn.request.body)
      {er, v} <- Grasp.run(s, i)
      string_value = if is_boolean(v), do: to_string(v), else: v
      pure %{extract_resultant: er, value: string_value}
    end
    |> handle_with_200_json(conn)
  end
end
