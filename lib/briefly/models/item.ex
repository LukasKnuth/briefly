defmodule Briefly.Models.Item do
  @moduledoc """
  A Feed Item, extracted from a Feed.
  """

  defstruct feed: nil, title: nil, link: nil, date: nil, group: nil

  def add_group(%__MODULE__{} = state, group) do
    %__MODULE__{state | group: group}
  end

  def maybe_override_feed(%__MODULE__{} = state, override) when is_binary(override) do
    %__MODULE__{state | feed: override}
  end

  def maybe_override_feed(%__MODULE__{} = state, _), do: state
end
