defmodule Grimoire.Puzzles.Fibonacci do
  @moduledoc """
  Efficient Fibonacci sequence implementation.
  """

  @doc """
  Returns the nth Fibonacci number.

  The "nth" means the number at position n in the sequence:
  - fib(0) = 0 (0th position)
  - fib(1) = 1 (1st position)
  - fib(2) = 1 (2nd position)
  - fib(3) = 2 (3rd position)
  - etc.

  Uses iterative approach for O(n) time complexity, meaning the
  algorithm runs in linear time proportional to n (much faster
  than the exponential O(2^n) recursive approach).

  ## Examples

      iex> Grimoire.Puzzles.Fibonacci.fib(10)
      55
  """
  @spec fib(non_neg_integer()) :: non_neg_integer()
  def fib(0), do: 0
  def fib(1), do: 1
  def fib(n) when n < 0, do: raise(ArgumentError, "negative numbers not supported")

  def fib(n) do
    # Start with fib(0)=0, fib(1)=1 and iterate from 2 to n
    {_, result} = Enum.reduce(2..n, {0, 1}, fn _, {prev, curr} ->
      # Each step: prev becomes curr, curr becomes prev + curr
      {curr, prev + curr}
    end)
    result
  end
end
