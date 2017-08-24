use Croma

defmodule Yubot.Grasp.StringResponder do
  alias Croma.Result, as: R
  alias Yubot.Grasp.{Responder, Extractor}

  defmodule Mode do
    use Croma.SubtypeOfAtom, values: [:string], default: :string
  end

  defmodule StringMaker do
    @fallback_string "[Error: Could not generate value here]"
    @moduledoc """
    Generator of one-arity functions which generate strings from source lists.

    Available operators:
    - `:Join` - Join all elements in the list with specified delimiter.
    - `:At` - Pick an element at specified index.

    Note that `:At` operator uses `Enum.at/2` as runtime build block, which takes linear time.

    If string generation somehow failed, "#{@fallback_string}" will be inserted instead.
    """

    @operators [:Join, :At]
    @type operator_t :: unquote(Croma.TypeUtil.list_to_type_union(@operators))
    @type t :: %{
      operator: operator_t,
      arguments: list,
    }

    defun valid?(term :: term) :: boolean do
      %{operator: op, arguments: args} when op in @operators and is_list(args) -> true
      _otherwise -> false
    end

    @spec new(term) :: R.t(t)
    def new(%{operator: op, arguments: args}),
      do: new_impl(op, args) |> R.map(fn {op_atom, args} -> %{operator: op_atom, arguments: args} end)
    def new(%{"operator" => op, "arguments" => args}),
      do: new_impl(op, args) |> R.map(fn {op_atom, args} -> %{operator: op_atom, arguments: args} end)
    def new(_),
      do: {:error, {:invalid_value, [__MODULE__]}}

    defp new_impl(join, [delimiter] = args) when join in [:Join, "Join"] and is_binary(delimiter) do
      {:ok, {:Join, args}}
    end
    defp new_impl(at, [index_str] = args) when at in [:At, "At"] and is_binary(index_str) do
      case Integer.parse(index_str) do
        {index, ""} when index >= 0 -> {:ok, {:At, args}}
        _otherwise -> {:error, {:invalid_value, [__MODULE__]}}
      end
    end
    defp new_impl(_, _) do
      {:error, {:invalid_value, [__MODULE__]}}
    end

    # Runtime functions

    @type fun_t :: (list -> String.t)

    @spec fun(t) :: fun_t
    def fun(%{operator: :Join, arguments: [delimiter]}), do: &join(&1, delimiter)
    def fun(%{operator: :At, arguments: [index_str]}), do: &at(&1, String.to_integer(index_str))
    # Crash for invalid string maker data

    defp join(list, delimiter) when is_list(list) and is_binary(delimiter), do: Enum.join(list, delimiter)
    defp join(_, _), do: @fallback_string

    defp at(list, index) when is_list(list) and index < length(list), do: to_string(Enum.at(list, index))
    defp at(_, _), do: @fallback_string

    # For test
    def fallback_string, do: @fallback_string
  end

  defmodule HighOrder do
    @fallback_string "[Error: No matched element]"
    @moduledoc """
    Router of high-order functions for `StringResponder`.

    - `:First` - Apply string maker to first element of source list. Emit "#{@fallback_string}" for empty source list.
    - `:JoinAll` - Join all elements with "\\n" as delimiter.
    """

    use Croma.SubtypeOfAtom, values: [:First, :JoinAll]

    @spec exec(Extractor.resultant_t, t, StringMaker.fun_t) :: String.t
    def exec([s | _ss], :First, string_maker_fun), do: string_maker_fun.(s)
    def exec([], :First, _string_maker_fun), do: @fallback_string
    def exec(source, :JoinAll, string_maker_fun), do: Enum.map_join(source, "\n", string_maker_fun)
    # Crash for invalid applications

    # For test
    def fallback_string, do: @fallback_string
  end

  use Croma.Struct, recursive_new?: true, fields: [
    mode: Mode,
    high_order: HighOrder,
    first_order: StringMaker,
  ]

  @behaviour Responder

  def respond(%__MODULE__{mode: :string, high_order: ho, first_order: fo}, source),
    do: HighOrder.exec(source, ho, StringMaker.fun(fo))
  def respond(r, _),
    do: "Invalid responder: #{inspect(r)}"
end
