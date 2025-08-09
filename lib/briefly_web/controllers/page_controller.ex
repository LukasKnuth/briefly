defmodule BrieflyWeb.PageController do
  use BrieflyWeb, :controller

  @doc "A configurable start view for the feed"
  def home(conn, _params) do
    path_params =
      :briefly
      |> Application.fetch_env!(__MODULE__)
      |> Keyword.fetch!(:home_action)
      |> then(&%{"days" => &1})

    # NOTE: Set `path_params` in conn also, so that the header marks the correct entry as active.
    %Plug.Conn{conn | path_params: path_params}
    # NOTE: Why not redirect? CURL does not follow redirects by default. We want to make
    # using clients other than browsers simple.
    |> feed(path_params)
  end

  @doc "Lists any problems encountered while parsing the feeds"
  def problems(conn, _params) do
    render(conn, :problems, problems: Briefly.list_problems())
  end

  @doc "Refreshes the feeds and renders out the home page"
  def refresh(conn, params) do
    :ok = Briefly.refresh()
    home(conn, params)
  end

  @doc "Renders the items parsed from all configured feeds"
  def feed(conn, params) do
    params
    |> list_opts()
    |> Briefly.list_items()
    |> Enum.group_by(& &1.group)
    |> Enum.sort()
    |> then(&render(conn, :feed, grouped_items: &1))
  end

  defp list_opts(params) do
    with {:ok, days} <- Map.fetch(params, "days"),
         number when is_integer(number) <- parse_to_days(days) do
      [days_ago: max(0, number)]
    else
      :error -> [days_ago: 0]
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
