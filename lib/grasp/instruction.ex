use Croma

defmodule Yubot.Grasp.Instruction do
  alias Yubot.Grasp.{RegexExtractor, BooleanResponder, StringResponder}

  use Croma.Struct, recursive_new?: true, fields: [
    extractor: RegexExtractor,
    responder: Croma.TypeGen.union([BooleanResponder, StringResponder]),
  ]
end
