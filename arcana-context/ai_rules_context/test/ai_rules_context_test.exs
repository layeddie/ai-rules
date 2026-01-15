defmodule AiRulesContextTest do
  use ExUnit.Case
  doctest AiRulesContext

  test "greets the world" do
    assert AiRulesContext.hello() == :world
  end
end
