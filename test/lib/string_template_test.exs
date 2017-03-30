defmodule Yubot.StringTemplateTest do
  use Croma.TestCase, alias_as: ST

  test "shoud parse string into template struct" do
    assert ST.parse(~S""                              ) == {:ok, %ST{body: ~S""                              , variables: []}}
    assert ST.parse(~S"no variables"                  ) == {:ok, %ST{body: ~S"no variables"                  , variables: []}}
    assert ST.parse(~S"one variable: #{var1}"         ) == {:ok, %ST{body: ~S"one variable: #{var1}"         , variables: ["var1"]}}
    assert ST.parse(~S"two variables: #{var1} #{var2}") == {:ok, %ST{body: ~S"two variables: #{var1} #{var2}", variables: ["var1", "var2"]}}
    assert ST.parse(~S"two positions: #{var1} #{var1}") == {:ok, %ST{body: ~S"two positions: #{var1} #{var1}", variables: ["var1"]}}
  end

  test "should reject invalid string" do
    assert ST.parse(~S"#{}"            ) == {:error, {:invalid_value, ""}} # No variable name
    assert ST.parse(~S"#{space in var}") == {:error, {:invalid_value, "space in var"}}
    assert ST.parse(~S"#{nested#{var}}") == {:error, {:invalid_value, ~S"nested#{var"}}
  end

  test "should render with variables" do
    assert ST.parse!("")                     |> ST.render()                    == {:ok, ""}
    assert ST.parse!("no variables")         |> ST.render()                    == {:ok, "no variables"}
    assert ST.parse!(~S({"var1":#{var1}}))   |> ST.render(%{"var1" => true})   == {:ok, ~S({"var1":true})}
    assert ST.parse!(~S({"var1":#{var1}}))   |> ST.render(%{"var1" => "true"}) == {:ok, ~S({"var1":true})}
    assert ST.parse!(~S({"var1":"#{var1}"})) |> ST.render(%{"var1" => "true"}) == {:ok, ~S({"var1":"true"})}

    template = ~S"""
    {
      "var1": "#{var1}",
      "var1_description": "var1 is '#{var1}'",
      "var2": "#{var2}",
      "var2_description": "var2 is '#{var2}'",
    }
    """
    {:ok, result} = ST.parse!(template) |> ST.render(%{"var1" => "foo", "var2" => "bar"})
    assert result == """
    {
      "var1": "foo",
      "var1_description": "var1 is 'foo'",
      "var2": "bar",
      "var2_description": "var2 is 'bar'",
    }
    """
  end
end
