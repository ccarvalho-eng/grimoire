defmodule Grimoire.Puzzles.FibonacciTest do
  use ExUnit.Case
  doctest Grimoire.Puzzles.Fibonacci

  alias Grimoire.Puzzles.Fibonacci

  test "base cases" do
    assert Fibonacci.fib(0) == 0
    assert Fibonacci.fib(1) == 1
  end

  test "some values" do
    assert Fibonacci.fib(2) == 1
    assert Fibonacci.fib(10) == 55
    assert Fibonacci.fib(30) == 832_040
  end

  test "large n fast" do
    assert is_integer(Fibonacci.fib(1000))
  end

  test "negative raises" do
    assert_raise ArgumentError, fn -> Fibonacci.fib(-1) end
  end
end
