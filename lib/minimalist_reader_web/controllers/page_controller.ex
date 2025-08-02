defmodule MinimalistReaderWeb.PageController do
  use MinimalistReaderWeb, :controller

  @doc "Renders the items parsed from all configured feeds"
  def feed(conn, _params) do
    # TODO Get days ago from param
    # TODO get timezone from user
    MinimalistReader.list_items(0, "Etc/UTC")
    |> Enum.group_by(& &1.group)
    |> Enum.sort()
    |> then(&render(conn, :feed, grouped_items: &1))
  end
end
