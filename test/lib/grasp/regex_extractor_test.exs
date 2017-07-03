defmodule Yubot.Grasp.RegexExtractorTest do
  use Croma.TestCase, async: true

  test "should validate/invalidate maps" do
    assert RegexExtractor.validate(%{"engine" => "regex", "pattern" => ".*"}) == {:ok, %RegexExtractor{engine: :regex, pattern: ".*"}}

    assert RegexExtractor.validate(%{"engine" => "invalid_engine", "pattern" => ".*"}) == {:error, {:invalid_value, [RegexExtractor]}}
    assert RegexExtractor.validate(%{"engine" => "regex", "pattern" => "*."}) == {:error, {:invalid_value, [RegexExtractor]}}
  end

  test "should extract in Extractor.esultant_t (2-dimension list)" do
    e0 = %RegexExtractor{engine: :regex, pattern: "pattern that should not match"}
    assert RegexExtractor.extract(e0, "test string") == {:ok, []}
    e1 = %RegexExtractor{engine: :regex, pattern: "\\w+"}
    assert RegexExtractor.extract(e1, "test string") == {:ok, [["test"], ["string"]]}
    e2 = %RegexExtractor{engine: :regex, pattern: "(\\w+) (\\w+)"}
    assert RegexExtractor.extract(e2, "test string") == {:ok, [["test string", "test", "string"]]}
    e3 = %RegexExtractor{engine: :regex, pattern: ~S/".+?":(".+?"|\d+|true|false)/}
    assert RegexExtractor.extract(e3, ~S'{"key1":"var","key2":true,"key3":1}')
      == {:ok, [[~S'"key1":"var"', ~S'"var"'], [~S'"key2":true', "true"], [~S'"key3":1', "1"]]}
  end
end
