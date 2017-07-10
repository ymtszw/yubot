defmodule Yubot.Grasp.InstructionTest do
  use Croma.TestCase, async: true
  alias Yubot.Grasp.{RegexExtractor, BooleanResponder}

  test "should validate/1 (new/1) from map" do
    assert Instruction.validate(%{
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
