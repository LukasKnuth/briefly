defmodule MinimalistReader.FeedParser do
  @behaviour Saxy.Handler

  alias MinimalistReader.FeedParser.RSS

  defstruct mod: nil, current: nil, feed_title: nil, items: []

  def parse_stream(stream) do
    Saxy.parse_stream(stream, __MODULE__, nil)
  end

  def handle_event(:start_element, {"rss", _attr}, nil) do
    # TODO does RSS version matter?
    {:ok, %__MODULE__{mod: RSS}}
  end

  def handle_event(:start_element, {"atom", _attr}, nil) do
    # TODO
    # {:ok, %__MODULE__{type: :atom}}
    {:ok, nil}
  end

  def handle_event(:end_document, _, %__MODULE__{items: items}) do
    # Just return the items, not the complete state.
    {:stop, items}
  end

  def handle_event(event, data, %__MODULE__{mod: module} = state) do
    module.handle_event(event, data, state)
  rescue
    # No handler for this event, ignore.
    _e in FunctionClauseError -> {:ok, state}
  end

  # Ingnores events _before_ we know which type of feed it is.
  def handle_event(_event, _data, state), do: {:ok, state}
end
