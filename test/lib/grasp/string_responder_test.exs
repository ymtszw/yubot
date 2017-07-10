defmodule Yubot.Grasp.StringResponderTest do
  use Croma.TestCase, async: true

  test "StringResponder should validate maps" do
    ho_pairs = [{"First", :First}, {"JoinAll", :JoinAll}]
    fo_pairs = [{{"Join", [","]}, {:Join, [","]}}, {{"At", ["1"]}, {:At, ["1"]}}]
    for {ho, expected_ho} <- ho_pairs,
        {{op, args}, {expected_op, expected_args}} <- fo_pairs do
      assert StringResponder.validate(%{
        "mode" => "string", "high_order" => ho,
        "first_order" => %{
          "operator" => op,
          "arguments" => args
        }
      }) == {:ok, %StringResponder{
        mode: :string, high_order: expected_ho,
        first_order: %{
          operator: expected_op,
          arguments: expected_args,
        }
      }}
    end
  end

  test "StringResponder should invalidate maps" do
    assert StringResponder.validate(%{
      "mode" => "invalid_mode", "high_order" => "First",
      "first_order" => %{
        "operator" => "Join",
        "arguments" => [","]
      }
    }) == {:error, {:invalid_value, [StringResponder, StringResponder.Mode]}}

    assert StringResponder.validate(%{
      "mode" => "string", "high_order" => "NonExisting",
      "first_order" => %{
        "operator" => "Join",
        "arguments" => [","]
      }
    }) == {:error, {:invalid_value, [StringResponder, StringResponder.HighOrder]}}

    assert StringResponder.validate(%{
      "mode" => "string", "high_order" => "First",
      "first_order" => %{
        "operator" => "NonExisting",
        "arguments" => [","]
      }
    }) == {:error, {:invalid_value, [StringResponder, StringResponder.StringMaker]}}

    assert StringResponder.validate(%{
      "mode" => "string", "high_order" => "First",
      "first_order" => %{
        "operator" => "Join",
        "arguments" => ["insufficient", "arguments"]
      }
    }) == {:error, {:invalid_value, [StringResponder, StringResponder.StringMaker]}}
  end

  test "should consume Extractor.resultant_t (2-dimension list) and respond with string" do
    r1 = %StringResponder{mode: :string, high_order: :First, first_order: %{operator: :Join, arguments: [","]}}
    assert StringResponder.respond(r1, [["abc"]]) == "abc"
    assert StringResponder.respond(r1, [["abc", "def"]]) == "abc,def"
    assert StringResponder.respond(r1, [["abc", "def"], ["ghi", "jkl"]]) == "abc,def"
    r2 = %StringResponder{mode: :string, high_order: :JoinAll, first_order: %{operator: :Join, arguments: [","]}}
    assert StringResponder.respond(r2, [["abc", "def"], ["ghi", "jkl"]]) == "abc,def\nghi,jkl"
    r3 = %StringResponder{mode: :string, high_order: :JoinAll, first_order: %{operator: :At, arguments: ["1"]}}
    assert StringResponder.respond(r3, [["abc", "def"], ["ghi", "jkl"]]) == "def\njkl"

    r4 = %StringResponder{mode: :string, high_order: :First, first_order: %{operator: :Join, arguments: [","]}}
    assert StringResponder.respond(r4, []) == StringResponder.HighOrder.fallback_string()
    r5 = %StringResponder{mode: :string, high_order: :First, first_order: %{operator: :At, arguments: ["1"]}}
    assert StringResponder.respond(r5, [["abc"]]) == StringResponder.StringMaker.fallback_string()
  end
end
