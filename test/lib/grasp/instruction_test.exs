defmodule Yubot.Grasp.InstructionTest do
  use Croma.TestCase, async: true
  alias Yubot.Grasp.{RegexExtractor, BooleanResponder}

  test "new/1 should generate Instruction from map" do
    assert Instruction.new(%{
      "extractor" => %{
        "engine" => "regex",
        "pattern" => ~S'"field":"(.+)"'
      },
      "responder" => %{
        "mode" => "boolean",
        "high_order" => "First",
        "first_order" => %{
          "operator" => "EqAt",
          "arguments" => ["1", "true"]
        }
      }
    }) == {:ok, %Instruction{
      extractor: %RegexExtractor{
        engine: :regex,
        pattern: ~S'"field":"(.+)"',
      },
      responder: %BooleanResponder{
        mode: :boolean,
        high_order: :First,
        first_order: %{
          operator: :EqAt,
          arguments: ["1", "true"],
        }
      }
    }}
  end
end
