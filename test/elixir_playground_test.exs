defmodule GrimoireTest do
  use ExUnit.Case
  doctest Grimoire

  test "greets the world" do
    assert Grimoire.hello() == :world
  end
end
