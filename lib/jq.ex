use Croma

defmodule Yubot.Jq do
  @moduledoc """
  Interface to system's "jq" CLI tool.

  Used for describing user action against polling result or webhook payload.

  https://stedolan.github.io/jq/manual/
  """

  alias :os, as: OS # Sneaky workaround to avoid solomon static analysis
  alias Croma.Result, as: R
  require Yubot.TypeGen

  @type option :: :pretty
  @type options :: [{option, boolean}]

  defmodule Filter do
    @max_byte 4_096
    def max_byte(), do: @max_byte
    Yubot.TypeGen.limited_byte_string_body(@max_byte)
  end

  defmodule Json do
    @system_arg_max OS.cmd(~c(getconf ARG_MAX)) |> List.to_string() |> String.trim_trailing() |> String.to_integer()
    @max_byte @system_arg_max - Filter.max_byte() - 128
    Yubot.TypeGen.limited_byte_string_body(@max_byte)
  end

  @doc """
  Run jq against `map_or_json` with `filter`.
  """
  defun run(map_or_json :: map | String.t, filter :: String.t, options :: options \\ []) :: R.t(String.t) do
    (map, filter, options) when is_map(map) ->
      Poison.encode!(map) |> run_impl(filter, options)
    (json, filter, options) ->
      run_impl(json, filter, options)
  end

  defunp run_impl(json0 :: v[Json.t], filter0 :: v[Filter.t], options :: Keyword.t) :: R.t(String.t) do
    R.m do
      json1 <- Json.validate(json0)
      filter1 <- Filter.validate(filter0)
      jq_opts = run_options_to_jq_options(options)
      try_jq(json1, filter1, jq_opts)
    end
  end

  defp run_options_to_jq_options(options) do
    %{
      "--compact-output" => !:proplists.get_bool(:pretty, options),
      # More may come?
    }
    |> Enum.filter_map(&(elem(&1, 1) == true), &elem(&1, 0))
    |> Enum.join(" ")
  end

  defp try_jq(json, filter, jq_opts) do
    case OS.cmd(~c(echo '#{json}' | jq #{jq_opts} '#{filter}')) |> List.to_string() |> String.replace_suffix("\n", "") do
      "parse error:" <> _ = error ->
        {:error, error}
      "jq:" <> _ = error ->
        {:error, error}
      success ->
        {:ok, success}
    end
  end
end
