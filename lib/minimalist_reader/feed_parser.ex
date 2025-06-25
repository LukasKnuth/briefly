defmodule MinimalistReader.FeedParser do
  @behaviour Saxy.Handler

  alias MinimalistReader.Models.{Feed, Item}

  defstruct type: nil, current: nil, feed: nil, items: []

  def parse_stream(stream) do
    Saxy.parse_stream(stream, __MODULE__, nil)
  end

  def handle_event(:start_element, {"rss", _attr}, nil) do
    # TODO does RSS version matter?
    {:ok, %__MODULE__{type: :rss}}
  end

  def handle_event(:start_element, {"atom", _attr}, nil) do
    {:ok, %__MODULE__{type: :atom}}
  end

  # -------- RSS Parser ----------
  @rss_item_elements ~w(title link pubDate)
  @rss_datetime_fmt "{WDshort}, {D} {Mshort} {YYYY} {h24}:{0m}:{0s} {Z}"

  def handle_event(:start_element, {"channel", _}, %__MODULE__{current: nil} = state) do
    {:ok, %{state | current: {:feed, nil}}}
  end

  def handle_event(:start_element, {"title", _}, %__MODULE__{current: {:feed, nil}} = state) do
    {:ok, %{state | current: {:feed, :title}}}
  end

  def handle_event(:characters, chars, %__MODULE__{current: {:feed, :title}} = state) do
    {:ok, %{state | current: nil, feed: %Feed{title: chars}}}
  end

  def handle_event(:start_element, {"item", _}, %__MODULE__{current: nil} = state) do
    {:ok, %{state | current: {:item, nil, %{}}}}
  end

  def handle_event(:start_element, {element, _}, %__MODULE__{current: {:item, _, map}} = state)
      when element in @rss_item_elements do
    {:ok, %{state | current: {:item, element, map}}}
  end

  def handle_event(:characters, chars, %__MODULE__{current: {:item, element, map}} = state)
      when is_binary(element) do
    {:ok, %{state | current: {:item, nil, Map.put(map, element, chars)}}}
  end

  def handle_event(:end_element, "item", %__MODULE__{current: {:item, _, map}} = state) do
    with {:ok, title} <- Map.fetch(map, "title"),
         {:ok, link} <- Map.fetch(map, "link"),
         {:ok, published} <- Map.fetch(map, "pubDate"),
         {:ok, pub_date} <- published |> String.trim() |> Timex.parse(@rss_datetime_fmt) do
      item = %Item{title: String.trim(title), link: String.trim(link), pub_date: pub_date}
      {:ok, %{state | current: nil, items: [item | state.items]}}
    else
      # Item didn't have required fields, ignore it
      :error ->
        {:ok, %{state | current: nil}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def handle_event(_ignored, _data, state), do: {:ok, state}
end
