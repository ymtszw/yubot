use Croma

defmodule Yubot.Grasp.BooleanResponder do
  alias Croma.Result, as: R
  alias Yubot.Grasp.{Responder, Extractor}

  defmodule Mode do
    use Croma.SubtypeOfAtom, values: [:boolean], default: :boolean
  end

  defmodule Predicate do
    @moduledoc """
    Generator of one-arity functions (predicates) which return `boolean` values from given lists.

    Available operators:
    - `:Contains` - `true` if an argument is contained in the list.
    - `:**At` - Apply one of basic comparison operators to element at specified index. `false` if the index was out of bound.

    Note that `:**At` operators will use `Enum.at/2` as runtime builing block, which takes linear time.
    """

    @indexed_operators [:EqAt, :NeAt, :LtAt, :LteAt, :GtAt, :GteAt]
    @type operator_t :: :Contains | :EqAt | :NeAt | :LtAt | :LteAt | :GtAt | :GteAt
    @type t :: %{
      operator: operator_t,
      arguments: list,
    }

    @spec validate(term) :: R.t(t)
    def validate(%{operator: op, arguments: args}) do
      validate_impl(op, args)
      |> R.map(fn {op_atom, args} -> %{operator: op_atom, arguments: args} end)
    end
    def validate(%{"operator" => op, "arguments" => args}) do
      validate_impl(op, args)
      |> R.map(fn {op_atom, args} -> %{operator: op_atom, arguments: args} end)
    end
    def validate(_) do
      {:error, {:invalid_value, [__MODULE__]}}
    end

    defp validate_impl(contains, [_right] = args) when contains in [:Contains, "Contains"],
      do: {:ok, {:Contains, args}}
    for op_atom <- @indexed_operators do
      @op_atom op_atom
      @op_str Atom.to_string(@op_atom)
      defp validate_impl(op, [index, _right] = args) when op in [@op_atom, @op_str] and is_integer(index) and index >= 0,
        do: {:ok, {@op_atom, args}}
    end
    defp validate_impl(_, _), do: {:error, {:invalid_value, [__MODULE__]}}

    defun new(term :: term) :: R.t(t), do: validate(term)

    # Runtime functions

    @type fun_t :: (list -> boolean)

    @spec fun(t) :: fun_t
    def fun(%{operator: :Contains, arguments: [right]}),
      do: &contains(&1, right)
    def fun(%{operator: :EqAt, arguments: [index, right]}),
      do: &eq_at(&1, index, right)
    def fun(%{operator: :NeAt, arguments: [index, right]}),
      do: &ne_at(&1, index, right)
    def fun(%{operator: :LtAt, arguments: [index, right]}),
      do: &lt_at(&1, index, right)
    def fun(%{operator: :LteAt, arguments: [index, right]}),
      do: &lte_at(&1, index, right)
    def fun(%{operator: :GtAt, arguments: [index, right]}),
      do: &gt_at(&1, index, right)
    def fun(%{operator: :GteAt, arguments: [index, right]}),
      do: &gte_at(&1, index, right)
    # Crash for invalid predicate data

    defp contains(list, right) when is_list(list), do: right in list
    defp contains(_, _), do: false

    defp eq_at(list, index, right)  when is_list(list) and index >= 0 and index < length(list), do: Enum.at(list, index) == right
    defp eq_at(_, _, _), do: false

    defp ne_at(list, index, right)  when is_list(list) and index >= 0 and index < length(list), do: Enum.at(list, index) != right
    defp ne_at(_, _, _), do: false

    defp lt_at(list, index, right)  when is_list(list) and index >= 0 and index < length(list), do: Enum.at(list, index) < right
    defp lt_at(_, _, _), do: false

    defp lte_at(list, index, right)  when is_list(list) and index >= 0 and index < length(list), do: Enum.at(list, index) <= right
    defp lte_at(_, _, _), do: false

    defp gt_at(list, index, right)  when is_list(list) and index >= 0 and index < length(list), do: Enum.at(list, index) > right
    defp gt_at(_, _, _), do: false

    defp gte_at(list, index, right)  when is_list(list) and index >= 0 and index < length(list), do: Enum.at(list, index) >= right
    defp gte_at(_, _, _), do: false
  end

  defmodule HighOrder do
    @moduledoc """
    Router of high-order functions for `BooleanResponder`.

    - `:First` - Apply predicate to first element of source list. `false` for empty source list.
    - `:Any` - Return `true` if at least one element resulted in `true` for predicate. `false` for empty source list.
    - `:All` - Return `true` if all elements resulted in `true` for predicate. `true` for empty source list.
    """

    use Croma.SubtypeOfAtom, values: [:First, :Any, :All]

    # Runtime functions

    @spec exec(Extractor.resultant_t, t, Predicate.fun_t) :: boolean
    def exec([s | _ss], :First, predicate_fun), do: predicate_fun.(s)
    def exec([], :First, _predicate_fun), do: false
    def exec(source, :Any, predicate_fun), do: Enum.any?(source, predicate_fun)
    def exec(source, :All, predicate_fun), do: Enum.all?(source, predicate_fun)
    # Crash for invalid applications
  end

  use Croma.Struct, recursive_new?: true, fields: [
    mode: Mode,
    high_order: HighOrder,
    first_order: Predicate,
  ]

  @behaviour Responder

  @spec respond(t, Extractor.resultant_t) :: boolean
  def respond(%__MODULE__{mode: :boolean, high_order: ho, first_order: fo}, source),
    do: HighOrder.exec(source, ho, Predicate.fun(fo))
  # Crash for invalid applications
end
