defmodule Briefly.EnumAssertions do
  @moduledoc """
  Module with helpers to assert on enumerables.
  """

  import ExUnit.Assertions

  @doc """
  Asserts that the first enumerable contains all items of the second enumerable.
  The comparison between the two happens in the supplied `mapper` function.
  """
  def assert_list_exactly_ordered(result, expected, mapper) when is_function(mapper, 2) do
    assert Enum.count(result) == Enum.count(expected)

    for {left, right} <- Enum.zip(result, expected) do
      assert mapper.(left, right)
    end

    true
  end

  @doc """
  Asserts that the first enumerable has _exactly_ one entry that is the same as
  the expected value. The comparison happens in the given `mapper` function.
  """
  def assert_only_one(result, expected, mapper) when is_function(mapper, 2) do
    assert Enum.count(result) == 1
    assert mapper.(Enum.at(result, 0), expected)
    true
  end
end
