use Croma

defmodule Yubot.Grasp.Instruction do
  alias Croma.Result, as: R
  alias Yubot.Grasp.{RegexExtractor, BooleanResponder, StringResponder}

  defmodule AvailableResponderUnion do
    @type t :: BooleanResponder.t | StringResponder.t

    def new(term), do: BooleanResponder.new(term) |> R.or_else(StringResponder.new(term))

    def validate(term), do: new(term)
  end

  use Croma.Struct, recursive_new?: true, fields: [
    extractor: RegexExtractor,
    responder: AvailableResponderUnion,
  ]
end
