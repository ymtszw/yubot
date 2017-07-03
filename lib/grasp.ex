use Croma

defmodule Yubot.Grasp do
  @moduledoc """
  Instruction-driven text analyzer/processor.

  Using UpperCamelCase for operator atoms, for the sake of easier interoperability with Elm.
  """

  alias Croma.Result, as: R
  alias Yubot.Grasp.Instruction

  @doc """
  Run `instruction` against `source`.
  """
  defun run(source :: v[String.t], instruction :: term) :: R.t(term) do
    R.m do
      %Instruction{extractor: %e_module{} = e, responder: %r_module{} = r} <- Instruction.validate(instruction)
      resultant <- e_module.extract(e, source)
      pure {resultant, r_module.respond(r, resultant)}
    end
  end
end
