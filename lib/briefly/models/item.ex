defmodule Briefly.Models.Item do
  @moduledoc """
  A Feed Item, extracted from a Feed.
  """

  defstruct feed: nil, title: nil, link: nil, date: nil, group: nil

  def add_group(%__MODULE__{} = state, group) do
    %__MODULE__{state | group: group}
  end
end
