use Croma

defmodule Yubot.StringTemplate do
  @moduledoc ~S"""
  String template with placeholder syntax.

  It derives from Elixir's string interpolation itself, but with more limited capability.

  - Basic syntax: `~S"Insert #{variable} here."`
      - Notice the `~S` sigil; `#{}` must be escaped.
  - All occurances of `#{variable}` will be simply replaced with actual value of `variable`.
  - Placeholder name must be lowercase alphanumeric string with underscore.
  - You cannot nest `#{}` like `#{outer#{inner_variable}variable}`.
  """

  alias Croma.Result, as: R

  defmodule Variable do
    use Croma.SubtypeOfString, pattern: ~r/\A[a-z0-9_]+\Z/

    def validate_with_message(term) do
      validate(term)
      |> R.map_error(fn _ -> {:invalid_value, term} end)
    end
  end

  use Croma.Struct, fields: [
    body: Croma.String,
    variables: Croma.TypeGen.list_of(Variable),
  ]

  @doc """
  Parse template `body` and extract unique variables, then build `#{inspect(__MODULE__)}` struct.
  """
  defun parse(body :: v[String.t]) :: R.t(t) do
    extract_variables(body)
    |> R.bind(&new(%{body: body, variables: &1}))
  end

  @placeholder_pattern ~r/#\{(.*)\}/U

  defun extract_variables(body :: v[String.t]) :: R.t([Variable.t]) do
    Regex.scan(@placeholder_pattern, body, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(&Variable.validate_with_message/1)
    |> R.sequence()
  end

  @doc """
  Render `template` with variables in `dict`.

  If `dict` does not provide non-empty strings for all variables in `template`,
  it results in failure and return missing variable name.
  """
  defun render(template :: v[t], dict :: %{Variable.t => String.t} | [{Variable.t, String.t}] \\ []) :: R.t(String.t) do
    case template.variables do
      [] -> {:ok, template.body}
      vs -> render_impl(template.body, vs, dict)
    end
  end

  defp render_impl(body, variables, dict) do
    variables
    |> fetch_all(dict)
    |> R.map(&replace_all(&1, body))
  end

  defp fetch_all(variables, dict) do
    Enum.map(variables, fn variable ->
      case fetch_variable(dict, variable) do
        bool when is_boolean(bool) ->
          {:ok, {variable, bool}}
        str when is_binary(str) and byte_size(str) > 0 ->
          {:ok, {variable, str}}
        _nil_or_empty_string ->
          {:error, {:value_missing, variable}}
      end
    end)
    |> R.sequence()
  end

  defp fetch_variable(dict, variable) do
    case Enum.find(dict, fn {key, _val} -> key == variable end) do
      nil -> nil
      {_variable, value} -> value
    end
  end

  defp replace_all(variables, body) do
    Enum.reduce(variables, body, fn {variable, str}, acc_body ->
      String.replace(acc_body, ~S"#{" <> variable <> "}", to_string(str))
    end)
  end

  Croma.Result.define_bang_version_of(parse: 1, render: 2)
end
