defmodule MinimalistReader.FeedParser.Atom do
  alias MinimalistReader.FeedParser, as: State
  alias MinimalistReader.Models.Item

  @item_elements ~w(title published)

  def handle_event(:start_element, {"title", _}, %State{current: {:feed, nil}} = state) do
    {:ok, %{state | current: {:feed, :title}}}
  end

  def handle_event(:characters, chars, %State{current: {:feed, :title}} = state) do
    {:ok, %{state | current: nil, feed_title: String.trim(chars)}}
  end

  def handle_event(:start_element, {"entry", _}, %State{current: nil} = state) do
    {:ok, %{state | current: {:item, nil, %{}}}}
  end

  def handle_event(:start_element, {"link", attributes}, %State{current: {:item, _, map}} = state) do
    case fetch_attribute(attributes, "href") do
      nil ->
        # No link information available, don't set value
        {:ok, state}

      link when is_binary(link) ->
        entry = {link, fetch_attribute(attributes, "rel")}
        map = Map.update(map, "link", [entry], &[entry | &1])
        {:ok, %{state | current: {:item, nil, map}}}
    end
  end

  def handle_event(:start_element, {element, _}, %State{current: {:item, _, map}} = state)
      when element in @item_elements do
    {:ok, %{state | current: {:item, element, map}}}
  end

  def handle_event(:characters, chars, %State{current: {:item, element, map}} = state)
      when is_binary(element) do
    {:ok, %{state | current: {:item, nil, Map.put(map, element, String.trim(chars))}}}
  end

  def handle_event(:end_element, "entry", %State{current: {:item, _, map}} = state) do
    with {:ok, title} <- Map.fetch(map, "title"),
         {:ok, link_list} <- Map.fetch(map, "link"),
         {:ok, link} <- pick_link(link_list),
         {:ok, published} <- Map.fetch(map, "published"),
         {:ok, pub_date, _} <- DateTime.from_iso8601(published) do
      item = %Item{
        feed: state.feed_title,
        title: title,
        link: link,
        pub_date: pub_date
      }

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

  defp fetch_attribute(attributes, to_fetch) when is_list(attributes) do
    Enum.find_value(attributes, fn {name, val} ->
      if name == to_fetch, do: val, else: false
    end)
  end

  defp pick_link([{link, _rel}]), do: {:ok, link}

  defp pick_link(links) when is_list(links) do
    Enum.find_value(links, :error, fn {link, rel} ->
      if rel == "alternate" || rel == "" || is_nil(rel) do
        {:ok, link}
      else
        false
      end
    end)
  end
end
