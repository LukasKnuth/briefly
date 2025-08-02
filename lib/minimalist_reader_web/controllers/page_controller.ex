defmodule MinimalistReaderWeb.PageController do
  use MinimalistReaderWeb, :controller

  @doc "Renders the items parsed from all configured feeds"
  def feed(conn, _params) do
    # TODO Get days ago from param
    # TODO get timezone from user
    items = MinimalistReader.list_items(0, "Etc/UTC")
    render(conn, :feed, items: items)
  end
end
