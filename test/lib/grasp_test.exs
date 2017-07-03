defmodule Yubot.GraspTest do
  use Croma.TestCase, async: true
  alias Grasp.{Instruction, RegexExtractor, BooleanResponder}

  test "should grasp value from source according to instruction" do
    i1 = %Instruction{
      extractor: %RegexExtractor{engine: :regex, pattern: "^(.+)$"},
      responder: %BooleanResponder{
        mode: :boolean, high_order: :All,
        first_order: %{operator: :EqAt, arguments: [1, "true"]},
      }
    }
    assert Grasp.run("true", i1) == {:ok, {[["true", "true"]], true}}
    assert Grasp.run(
      """
      true
      true
      """,
      i1
    ) == {:ok, {[["true", "true"], ["true", "true"]], true}}
    assert Grasp.run(
      """
      true
      false
      """,
      i1
    ) == {:ok, {[["true", "true"], ["false", "false"]], false}}

    i2 = %Instruction{
      extractor: %RegexExtractor{
        engine: :regex,
        pattern: ~S/"updated_at":"(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\+\d\d:?\d\d)"/},
      responder: %BooleanResponder{
        mode: :boolean, high_order: :Any,
        first_order: %{operator: :GteAt, arguments: [1, "2017-07-01T00:00:00+00:00"]},
      }
    }
    assert Grasp.run(
      """
      {"list": [
        {"id":1,"updated_at":"2017-07-01T00:00:00+00:00"}
      ]}
      """,
      i2
    ) == {:ok, {[[~S/"updated_at":"2017-07-01T00:00:00+00:00"/, "2017-07-01T00:00:00+00:00"]], true}}
    assert Grasp.run(
      """
      {"list": [
        {"id":1,"updated_at":"2017-06-30T00:00:00+00:00"}
      ]}
      """,
      i2
    ) == {:ok, {[[~S/"updated_at":"2017-06-30T00:00:00+00:00"/, "2017-06-30T00:00:00+00:00"]], false}}
    assert Grasp.run(
      """
      {"list": [
        {"id":1,"updated_at":"2017-06-30T00:00:00+00:00"},
        {"id":2,"updated_at":"2017-07-01T00:00:00+00:00"}
      ]}
      """,
      i2
    ) == {:ok, {[
      [~S/"updated_at":"2017-06-30T00:00:00+00:00"/, "2017-06-30T00:00:00+00:00"],
      [~S/"updated_at":"2017-07-01T00:00:00+00:00"/, "2017-07-01T00:00:00+00:00"],
    ], true}}
  end
end
