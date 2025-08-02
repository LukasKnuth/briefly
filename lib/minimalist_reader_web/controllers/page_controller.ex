defmodule MinimalistReaderWeb.PageController do
  use MinimalistReaderWeb, :controller

  @doc "Renders the items parsed from all configured feeds"
  def feed(conn, params) do
    # TODO get timezone from user
    params
    |> days_ago()
    |> MinimalistReader.list_items("Etc/UTC")
    |> Enum.group_by(& &1.group)
    |> Enum.sort()
    |> then(&render(conn, :feed, grouped_items: &1))
  end

  defp days_ago(params) do
    with {:ok, days} <- Map.fetch(params, "days"),
         number when is_integer(number) <- parse_to_days(days) do
      max(0, number)
    else
      :error -> 0
    end
  end

  defp parse_to_days(path_param) do
    path_param
    |> String.trim()
    |> String.downcase()
    |> case do
      "today" -> 0
      "yesterday" -> 1
      days -> with {days, _rest} <- Integer.parse(days), do: days
    end
  end
end
