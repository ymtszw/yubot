use Croma

defmodule Yubot.Grasp do
  @moduledoc """
  Instruction-driven text analyzer/processor.

  Using UpperCamelCase for operator atoms, for the sake of easier interoperability with Elm.
  """

  alias Croma.Result, as: R
  alias Yubot.Grasp.Instruction

  defmodule TryRequest do
    use Croma.Struct, recursive_new?: true, fields: [
      source: Croma.String,
      instruction: Instruction,
    ]
  end

  @doc """
  Run `instruction` against `source`.
  """
  defun run(source :: v[String.t], instruction :: term, verbose? \\ true) :: R.t(term) do
    R.m do
      %Instruction{extractor: %e_module{} = e, responder: %r_module{} = r} <- Instruction.validate(instruction)
      er <- e_module.extract(e, source)
      r = r_module.respond(r, er)
      pure (if verbose?, do: {er, r}, else: r)
    end
  end
end
