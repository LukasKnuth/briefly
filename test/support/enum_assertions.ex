defmodule MinimalistReader.EnumAssertions do
  @moduledoc """
  Module with helpers to assert on enumerables.
  """

  import ExUnit.Assertions

  def assert_list_exactly_ordered(result, expected, mapper) when is_function(mapper, 2) do
    assert Enum.count(result) == Enum.count(expected)

    for {left, right} <- Enum.zip(result, expected) do
      assert mapper.(left, right)
    end

    true
  end
end
