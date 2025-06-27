defmodule MinimalistReader.FeedParser.RSS do
  alias MinimalistReader.FeedParser, as: State
  alias MinimalistReader.Models.Item

  @rss_item_elements ~w(title link pubDate)
  @rss_datetime_fmt "{WDshort}, {D} {Mshort} {YYYY} {h24}:{0m}:{0s} {Z}"

  def handle_event(:start_element, {"channel", _}, %State{current: nil} = state) do
    {:ok, %{state | current: {:feed, nil}}}
  end

  def handle_event(:start_element, {"title", _}, %State{current: {:feed, nil}} = state) do
    {:ok, %{state | current: {:feed, :title}}}
  end

  def handle_event(:characters, chars, %State{current: {:feed, :title}} = state) do
    {:ok, %{state | current: nil, feed_title: String.trim(chars)}}
  end

  def handle_event(:start_element, {"item", _}, %State{current: nil} = state) do
    {:ok, %{state | current: {:item, nil, %{}}}}
  end

  def handle_event(:start_element, {element, _}, %State{current: {:item, _, map}} = state)
      when element in @rss_item_elements do
    {:ok, %{state | current: {:item, element, map}}}
  end

  def handle_event(:characters, chars, %State{current: {:item, element, map}} = state)
      when is_binary(element) do
    {:ok, %{state | current: {:item, nil, Map.put(map, element, String.trim(chars))}}}
  end

  def handle_event(:end_element, "item", %State{current: {:item, _, map}} = state) do
    with {:ok, title} <- Map.fetch(map, "title"),
         {:ok, link} <- Map.fetch(map, "link"),
         {:ok, published} <- Map.fetch(map, "pubDate"),
         {:ok, pub_date} <- published |> Timex.parse(@rss_datetime_fmt) do
      item = %Item{feed: state.feed_title, title: title, link: link, pub_date: pub_date}
      {:ok, %{state | current: nil, items: [item | state.items]}}
    else
      # Item didn't have required fields, ignore it
      :error ->
        {:ok, %{state | current: nil}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Ignore any other elements
  def handle_event(_event, _data, state), do: {:ok, state}
end
