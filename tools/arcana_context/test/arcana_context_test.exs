defmodule ArcanaContextTest do
  use ExUnit.Case

  test "exposes default collection" do
    assert ArcanaContext.Docs.default_collection() == "ai_rules_docs"
  end
end
