defmodule Yubot.Grasp.BooleanResponderTest do
  use Croma.TestCase, async: true

  test "BooleanResponder should validate maps" do
    ho_pairs = [{"First", :First}, {"Any", :Any}, {"All", :All}]
    fo_pairs = [
      {{"Contains", [true]}, {:Contains, [true]}},
      {{"EqAt" , [1, true]}, {:EqAt , [1, true]}},
      {{"NeAt" , [1, true]}, {:NeAt , [1, true]}},
      {{"LtAt" , [1, 1]}, {:LtAt , [1, 1]}},
      {{"LteAt", [1, 1]}, {:LteAt, [1, 1]}},
      {{"GtAt" , [1, 1]}, {:GtAt , [1, 1]}},
      {{"GteAt", [1, 1]}, {:GteAt, [1, 1]}},
    ]
    for {ho, expected_ho} <- ho_pairs,
        {{op, args}, {expected_op, expected_args}} <- fo_pairs do
      assert BooleanResponder.validate(%{
        "mode" => "boolean", "high_order" => ho,
        "first_order" => %{
          "operator" => op,
          "arguments" => args
        }
      }) == {:ok, %BooleanResponder{
        mode: :boolean, high_order: expected_ho,
        first_order: %{
          operator: expected_op,
          arguments: expected_args,
        }
      }}
    end
  end

  test "BooleanResponder should invalidate maps" do
    assert BooleanResponder.validate(%{
      "mode" => "invalid_mode", "high_order" => "First",
      "first_order" => %{
        "operator" => "Contains",
        "arguments" => [true]
      }
    }) == {:error, {:invalid_value, [BooleanResponder, BooleanResponder.Mode]}}

    assert BooleanResponder.validate(%{
      "mode" => "boolean", "high_order" => "NonExisting",
      "first_order" => %{
        "operator" => "Contains",
        "arguments" => [true]
      }
    }) == {:error, {:invalid_value, [BooleanResponder, BooleanResponder.HighOrder]}}

    assert BooleanResponder.validate(%{
      "mode" => "boolean", "high_order" => "First",
      "first_order" => %{
        "operator" => "NonExisting",
        "arguments" => [true]
      }
    }) == {:error, {:invalid_value, [BooleanResponder, BooleanResponder.Predicate]}}

    assert BooleanResponder.validate(%{
      "mode" => "boolean", "high_order" => "First",
      "first_order" => %{
        "operator" => "Contains",
        "arguments" => ["insufficient", "arguments"]
      }
    }) == {:error, {:invalid_value, [BooleanResponder, BooleanResponder.Predicate]}}
  end

  test "should consume Extractor.resultant_t (2-dimension list) and respond with boolean" do
    r1 = %BooleanResponder{mode: :boolean, high_order: :First, first_order: %{operator: :Contains, arguments: ["abc"]}}
    assert BooleanResponder.respond(r1, []) == false
    assert BooleanResponder.respond(r1, [["abc"]]) == true
    assert BooleanResponder.respond(r1, [["abc", "def"]]) == true
    assert BooleanResponder.respond(r1, [["abc", "def"], ["ghi", "jkl"]]) == true
    r2 = %BooleanResponder{mode: :boolean, high_order: :First, first_order: %{operator: :Contains, arguments: ["abc"]}}
    assert BooleanResponder.respond(r2, [["ghi", "jkl"]]) == false
    r3 = %BooleanResponder{mode: :boolean, high_order: :All, first_order: %{operator: :Contains, arguments: ["abc"]}}
    assert BooleanResponder.respond(r3, []) == true
    assert BooleanResponder.respond(r3, [["abc", "def"], ["ghi", "jkl"]]) == false
    assert BooleanResponder.respond(r3, [["abc", "def"], ["abc", "def"]]) == true
    r4 = %BooleanResponder{mode: :boolean, high_order: :Any, first_order: %{operator: :Contains, arguments: ["abc"]}}
    assert BooleanResponder.respond(r4, []) == false
    assert BooleanResponder.respond(r4, [["abc", "def"]]) == true
    assert BooleanResponder.respond(r4, [["ghi", "jkl"]]) == false
    assert BooleanResponder.respond(r4, [["abc", "def"], ["ghi", "jkl"]]) == true
    r5 = %BooleanResponder{mode: :boolean, high_order: :First, first_order: %{operator: :EqAt, arguments: [1, "abc"]}}
    assert BooleanResponder.respond(r5, [["abc", "def"]]) == false
    assert BooleanResponder.respond(r5, [["def", "abc"]]) == true
    r6 = %BooleanResponder{mode: :boolean, high_order: :First, first_order: %{operator: :EqAt, arguments: [2, "abc"]}}
    assert BooleanResponder.respond(r6, [["abc", "def"]]) == false
  end
end
