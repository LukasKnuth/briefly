defmodule MinimalistReaderWeb.PageControllerTest do
  use MinimalistReaderWeb.ConnCase

  import MinimalistReader.EnumAssertions

  alias MinimalistReader.Storage
  alias MinimalistReader.Models.Item

  @app :minimalist_reader
  @home_mod MinimalistReaderWeb.PageController

  describe "GET /since/:days_ago" do
    setup do
      now = DateTime.now!("Etc/UTC") |> Timex.set(hour: 10, minute: 0, second: 0)

      Storage.replace(
        [
          make_item("itemA1", date: Timex.shift(now, hours: -1), group: "News"),
          make_item("itemA2", date: Timex.shift(now, hours: -2), group: "Blog"),
          make_item("itemA3", date: Timex.shift(now, hours: -3), group: "Fashion"),
          make_item("itemB1", date: Timex.shift(now, days: -1, hours: -1), group: "News"),
          make_item("itemB2", date: Timex.shift(now, days: -1, hours: -2), group: "Blog"),
          make_item("itemB3", date: Timex.shift(now, days: -1, hours: -3), group: "Fashion"),
          make_item("itemC1", date: Timex.shift(now, days: -2, hours: -1), group: "News"),
          make_item("itemC2", date: Timex.shift(now, days: -2, hours: -2), group: "Blog"),
          make_item("itemC3", date: Timex.shift(now, days: -2, hours: -3), group: "Fashion")
        ],
        []
      )

      :ok
    end

    for {path, expected} <- [
          # NOTE: Order is affected by the grouping.
          {"today", ~w(itemA2 itemA3 itemA1)},
          {"0d", ~w(itemA2 itemA3 itemA1)},
          {"yesterday", ~w(itemA2 itemB2 itemA3 itemB3 itemA1 itemB1)},
          {"1d", ~w(itemA2 itemB2 itemA3 itemB3 itemA1 itemB1)},
          {"2d", ~w(itemA2 itemB2 itemC2 itemA3 itemB3 itemC3 itemA1 itemB1 itemC1)},
          # NOTE: shows the same because there aren't more entries.
          {"3d", ~w(itemA2 itemB2 itemC2 itemA3 itemB3 itemC3 itemA1 itemB1 itemC1)},
          # NOTE: the "today" page is the fallback for invalid inputs
          {"invalid", ~w(itemA2 itemA3 itemA1)},
          {"-1d", ~w(itemA2 itemA3 itemA1)}
        ] do
      test "returns all items in date order since '#{path}'", %{conn: conn} do
        conn
        |> get(~p"/since/#{unquote(path)}")
        |> html_response(200)
        |> LazyHTML.from_document()
        |> LazyHTML.query("main .item a")
        |> assert_list_exactly_ordered(unquote(expected), fn element, expected ->
          LazyHTML.attribute(element, "href") == [expected]
        end)
      end
    end

    test "groups items alphabetically by their `group` property", %{conn: conn} do
      expected = [
        {"Blog", ~w(itemA2 itemB2 itemC2)},
        {"Fashion", ~w(itemA3 itemB3 itemC3)},
        {"News", ~w(itemA1 itemB1 itemC1)}
      ]

      conn
      |> get(~p"/since/3d")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query("main div.group")
      |> assert_list_exactly_ordered(expected, fn group, {name, items} ->
        group
        |> LazyHTML.query(".item a")
        |> assert_list_exactly_ordered(items, fn element, link ->
          LazyHTML.attribute(element, "href") == [link]
        end)

        LazyHTML.query(group, "h2") |> LazyHTML.text() == name
      end)
    end

    test "adds info box if there where problems reading feeds"
  end

  describe "GET /" do
    setup do
      old = Application.get_env(@app, @home_mod)
      Application.put_env(@app, @home_mod, home_action: "yesterday")
      on_exit(:env_cleanup, fn -> Application.put_env(@app, @home_mod, old) end)
    end

    test "renders the configured page without redirect", %{conn: conn} do
      conn
      |> get(~p"/")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query("main .item a")
      |> assert_list_exactly_ordered(~w(itemA2 itemB2 itemA3 itemB3 itemA1 itemB1), fn element,
                                                                                       link ->
        LazyHTML.attribute(element, "href") == [link]
      end)
    end
  end

  defp make_item(id, opts) do
    %Item{
      link: id,
      date: Keyword.get_lazy(opts, :date, fn -> DateTime.now!("Etc/UTC") end),
      title: "Mock #{id}",
      feed: Keyword.get(opts, :feed, "Test"),
      group: Keyword.get(opts, :group, nil)
    }
  end
end
