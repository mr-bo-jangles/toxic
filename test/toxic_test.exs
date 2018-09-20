defmodule ToxicTest do
  use ExUnit.Case
  doctest Toxic

  test "greets the world" do
    assert Toxic.hello() == :world
  end
end
