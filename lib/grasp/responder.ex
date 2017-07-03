use Croma

defmodule Yubot.Grasp.Responder do
  @moduledoc """
  Response generator behaviour module.

  Actual response modules must implement `respond/2` callback.
  They must generate values matching their `:mode` types.

  `Yubot.Grasp.Extractor.resultant_t` is 2-dimension `String.t` lists.
  They should be processed by high-order functions specified in `:high_order` fields
  with first-order functions in `:first_order` fields.
  """

  @type first_order_t :: %{
    operator: atom,
    arguments: list,
  }
  @type t :: %{
    mode: atom,
    high_order: atom,
    first_order: first_order_t,
  }

  @callback respond(responder :: t, source :: Extractor.resultant_t) :: any
end
