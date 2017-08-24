use Croma

defmodule Yubot.Grasp.Extractor do
  @moduledoc """
  Analysis/Processing target extractor behaviour module.

  Actual extraction modules must implementat `extract/2` callback.
  They must generate 2-dimension list of `String.t` (`resultant_t`), which  will be fed into `Responder`.

  Note that `:pattern` values must be serialized to `String.t`, since they are stored in DB.

  Currently only `RegexExtractor` is implemented.
  """

  @type t :: %{
    engine: atom, # At least currently, we can omit `:engine` specification since there is only a RegexExtractor
    pattern: String.t,
  }
  @type resultant_t :: [[String.t]]

  @callback extract(extractor :: t, source :: String.t) :: Croma.Result.t(resultant_t)
end

defmodule Yubot.Grasp.RegexExtractor do
  @moduledoc """
  Extractor using `Regex.scan/3`.

  Regex pattern must be written in string, and stored as string.
  Special charactor classes like "\\s" must be properly escaped.

  Regex options used are: "u" (unicode) "s" (dotall) and "m" (multiline).
  """

  alias Croma.Result, as: R
  alias Yubot.Grasp.Extractor

  defstruct [:engine, :pattern]

  @behaviour Extractor
  @type t :: %__MODULE__{
    engine: :regex,
    pattern: String.t,
  }

  defun valid?(term :: term) :: boolean do
    %__MODULE__{engine: :regex, pattern: p} -> validate_as_regex(p) |> R.ok?()
    _otherwise -> false
  end

  @spec new(term) :: R.t(t)
  def new(%{engine: e, pattern: p}) when e in [:regex, "regex"],
    do: validate_as_regex(p) |> R.map(&%__MODULE__{engine: :regex, pattern: &1})
  def new(%{"engine" => e, "pattern" => p}) when e in [:regex, "regex"],
    do: validate_as_regex(p) |> R.map(&%__MODULE__{engine: :regex, pattern: &1})
  def new(_),
    do: {:error, {:invalid_value, [__MODULE__]}}

  defp validate_as_regex(str) when is_binary(str) do
    case Regex.compile(str) do
      {:ok, _regex} -> {:ok, str}
      _error -> {:error, {:invalid_value, [__MODULE__]}}
    end
  end
  defp validate_as_regex(term) do
    if Regex.regex?(term), do: {:ok, Regex.source(term)}, else: {:error, {:invalid_value, [__MODULE__]}}
  end

  def extract(%__MODULE__{engine: :regex, pattern: p}, source) when is_binary(p),
    do: Regex.compile(p, "usm") |> R.map(&Regex.scan(&1, source))
  def extract(_, _),
    do: {:error, {:invalid_value, __MODULE__}}
end
