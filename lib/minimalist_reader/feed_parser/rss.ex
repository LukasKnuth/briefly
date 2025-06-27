defmodule MinimalistReader.FeedParser.RSS do
  @moduledoc """
  RSS specific pull-parser implementation, used by `MinimalistReader.FeedParser`.

  Implements a small subset of the Atom standard, as defined here:
  https://www.rssboard.org/rss-specification
  """
  alias MinimalistReader.FeedParser, as: State
  alias MinimalistReader.Models.Item

  @item_elements ~w(title link pubDate)

  def handle_event(:start_element, {"channel", _}, %State{current_type: nil} = state) do
    {:ok, %{state | current_type: :feed, current_element: nil}}
  end

  def handle_event(
        :start_element,
        {"title", _},
        %State{current_type: :feed, current_element: nil} = state
      ) do
    {:ok, %{state | current_element: "title"}}
  end

  def handle_event(
        :characters,
        chars,
        %State{current_type: :feed, current_element: "title"} = state
      ) do
    {:ok, %{state | current_element: nil, feed_title: String.trim(chars)}}
  end

  def handle_event(:start_element, {"item", _}, %State{current_element: nil} = state) do
    {:ok, %{state | current_type: :item, item_index: state.item_index + 1, partial: %{}}}
  end

  def handle_event(
        :start_element,
        {element, _},
        %State{current_type: :item, current_element: nil} = state
      )
      when element in @item_elements do
    {:ok, %{state | current_element: element}}
  end

  def handle_event(
        :characters,
        chars,
        %State{current_type: :item, current_element: element, partial: map} = state
      )
      when is_binary(element) do
    {:ok, %{state | current_element: nil, partial: Map.put(map, element, String.trim(chars))}}
  end

  def handle_event(
        :end_element,
        "item",
        %State{current_type: :item, current_element: nil, partial: map} = state
      ) do
    with {:ok, title} <- Map.fetch(map, "title"),
         {:ok, link} <- Map.fetch(map, "link"),
         {:ok, published} <- Map.fetch(map, "pubDate"),
         {:ok, date} <- published |> Timex.parse("{RFC1123}") do
      item = %Item{feed: state.feed_title, title: title, link: link, date: date}
      {:ok, %{state | items: [item | state.items]}}
    else
      # Item didn't have required fields, ignore it
      :error ->
        {:ok, %{state | problems: [{state.item_index, :missing_fields} | state.problems]}}

      {:error, reason} ->
        {:ok, %{state | problems: [{state.item_index, {:date, reason}} | state.problems]}}
    end
  end

  # Ignore any other elements
  def handle_event(_event, _data, state), do: {:ok, state}
end
