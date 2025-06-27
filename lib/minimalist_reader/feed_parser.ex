defmodule MinimalistReader.FeedParser do
  @moduledoc """
  A "smart" parser for XML based feeds like RSS and Atom.
  Will inspect the XML and pick the specific format accordingly.

  This is implemented as a pull-parser, so it can be very resource friendly
  for even large feeds.
  The parser works on a best-effort basis, meaning it returns all items it
  was able to parse and any errors it encountered for others.
  """
  @behaviour Saxy.Handler

  alias MinimalistReader.FeedParser.{Atom, RSS}

  defstruct mod: nil,
            current_element: nil,
            current_type: nil,
            partial: %{},
            item_index: -1,
            feed_title: nil,
            items: [],
            problems: []

  @type item :: %MinimalistReader.Models.Item{}
  @type problem :: {index :: pos_integer(), reason :: any()}
  @spec parse_stream(Stream.t()) :: {:ok, [item], [problem]} | {:error, %Saxy.ParseError{}}
  def parse_stream(stream) do
    with {:ok, state} <- Saxy.parse_stream(stream, __MODULE__, nil) do
      {:ok, Enum.reverse(state.items), Enum.reverse(state.problems)}
    end
  end

  def handle_event(:start_element, {"rss", _attr}, nil) do
    # TODO does RSS version matter?
    {:ok, %__MODULE__{mod: RSS}}
  end

  def handle_event(:start_element, {"feed", _attr}, nil) do
    # TODO do we _need_ to match on the `xmlns`?
    {:ok, %__MODULE__{mod: Atom, current_type: :feed, current_element: nil}}
  end

  def handle_event(event, data, %__MODULE__{mod: module} = state) do
    module.handle_event(event, data, state)
  end

  # NOTE: Ingnore events _before_ we know which type of feed it is.
  def handle_event(_event, _data, state), do: {:ok, state}
end
