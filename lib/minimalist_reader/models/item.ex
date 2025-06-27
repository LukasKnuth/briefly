defmodule MinimalistReader.Models.Item do
  @moduledoc """
  A Feed Item, extracted from a Feed.
  """

  defstruct feed: nil, title: nil, link: nil, date: nil
end
