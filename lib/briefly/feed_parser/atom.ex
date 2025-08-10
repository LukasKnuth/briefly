defmodule Briefly.FeedParser.Atom do
  @moduledoc """
  Atom specific pull-parser implementation, used by `Briefly.FeedParser`.

  Implements a small subset of the Atom standard, as defined here:
  https://validator.w3.org/feed/docs/atom.html
  """
  alias Briefly.Models.Problem
  alias Briefly.FeedParser, as: State
  alias Briefly.Models.Item

  @item_elements ~w(title published updated)

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

  def handle_event(:start_element, {"entry", _}, %State{current_element: nil} = state) do
    {:ok, %{state | current_type: :item, item_index: state.item_index + 1, partial: %{}}}
  end

  def handle_event(
        :start_element,
        {"link", attributes},
        %State{current_type: :item, current_element: nil, partial: map} = state
      ) do
    case fetch_attribute(attributes, "href") do
      nil ->
        # No link information available, don't set value
        problem = Problem.from_item(state.item_index, "link missing")
        {:ok, %{state | problems: [problem | state.problems]}}

      link when is_binary(link) ->
        rel = fetch_attribute(attributes, "rel")
        type = fetch_attribute(attributes, "type")
        entry = {link, rel, type}
        map = Map.update(map, "link", [entry], &[entry | &1])
        {:ok, %{state | partial: map}}
    end
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
        "entry",
        %State{current_type: :item, current_element: nil, partial: map} = state
      ) do
    with {:ok, title} <- Map.fetch(map, "title"),
         {:ok, link_list} <- Map.fetch(map, "link"),
         {:ok, link} <- pick_link(link_list),
         {:ok, date} <- pick_date(map),
         {:ok, date, _} <- DateTime.from_iso8601(date) do
      item = %Item{
        feed: state.feed_title,
        title: title,
        link: link,
        date: date
      }

      {:ok, %{state | items: [item | state.items]}}
    else
      :error ->
        # Item didn't have required fields, ignore it
        problem = Problem.from_item(state.item_index, "missing required fields")
        {:ok, %{state | problems: [problem | state.problems]}}

      {:error, _reason} ->
        problem = Problem.from_item(state.item_index, "invalid date format")
        {:ok, %{state | problems: [problem | state.problems]}}
    end
  end

  # Ignore any other elements
  def handle_event(_event, _data, state), do: {:ok, state}

  defp fetch_attribute(attributes, to_fetch) when is_list(attributes) do
    Enum.find_value(attributes, fn {name, val} ->
      if name == to_fetch, do: val, else: false
    end)
  end

  defp pick_date(%{"published" => date}), do: {:ok, date}
  defp pick_date(%{"updated" => date}), do: {:ok, date}
  defp pick_date(_), do: :error

  # coveralls-ignore-next-line
  defp pick_link([]), do: :error
  defp pick_link([{link, _rel, _type}]), do: {:ok, link}

  defp pick_link(links) when is_list(links) do
    links
    |> Enum.max_by(fn {_link, rel, type} ->
      weighted_score(rel: rel) + weighted_score(type: type)
    end)
    |> then(fn {link, _rel, _type} -> {:ok, link} end)
  end

  defp weighted_score(rel: rel), do: score_rel(rel) * 0.75
  defp weighted_score(type: type), do: score_type(type) * 0.25

  defp score_rel(rel) when rel in ["alternate", "", nil], do: 3
  defp score_rel("self"), do: 2
  defp score_rel(_rel), do: 1

  defp score_type("text/html"), do: 3
  defp score_type("text/" <> _rest), do: 2
  defp score_type(_type), do: 1
end
