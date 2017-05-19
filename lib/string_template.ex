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

  defstruct [:body, :variables]
  @type t :: %__MODULE__{body: String.t, variables: [Variable.t]}

  defun validate(v :: term) :: R.t(t) do
    (%{"body" => body, "variables" => vars}  ) when is_binary(body) and is_list(vars) -> validate_impl(body, vars)
    (%{body: body, variables: vars}          ) when is_binary(body) and is_list(vars) -> validate_impl(body, vars)
    (%__MODULE__{body: body, variables: vars}) when is_binary(body) and is_list(vars) -> validate_impl(body, vars)
    (_otherwise                              )                                        -> {:error, {:invalid_value, [__MODULE__]}}
  end

  defp validate_impl(body, vars) do
    extract_variables(body)
    |> R.bind(fn
      ^vars -> {:ok, %__MODULE__{body: body, variables: vars}}
      _else -> {:error, {:invalid_value, [__MODULE__]}} # `vars` in request and extraction result does not match; either client or this module went wrong
    end)
  end

  @doc """
  Parse template `body` in `dict`, and extract unique variables, then build `#{inspect(__MODULE__)}` struct.

  Ignores existing (or non-existing) `variables` field in `dict`.
  """
  defun new(dict :: map | list) :: R.t(t) do
    (%{"body" => body})                    -> extract_variables(body) |> R.map(&%__MODULE__{body: body, variables: &1})
    (%{body: body}    )                    -> extract_variables(body) |> R.map(&%__MODULE__{body: body, variables: &1})
    (list             ) when is_list(list) -> new_from_list(list)
    (_otherwise       )                    -> {:error, {:invalid_value, [__MODULE__]}}
  end

  defp new_from_list(list) do
    case list[:body] do
      nil -> {:error, {:value_missing, [__MODULE__, String]}}
      body -> extract_variables(body) |> R.map(&%__MODULE__{body: body, variables: &1})
    end
  end

  @placeholder_pattern ~r/#\{(.*)\}/U

  @spec extract_variables(term) :: R.t([Variable.t])
  def extract_variables(body) when is_binary(body) do
    Regex.scan(@placeholder_pattern, body, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(&Variable.validate_with_message/1)
    |> R.sequence()
  end
  def extract_variables(_), do: {:error, {:invalid_value, [String]}}

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

  Croma.Result.define_bang_version_of(validate: 1, new: 1, render: 2)
end
