defmodule BrieflyWeb.PageControllerTest do
  use BrieflyWeb.ConnCase

  import Briefly.EnumAssertions

  alias Briefly.Storage
  alias Briefly.Models.{Problem, Item}

  @app :briefly
  @home_mod BrieflyWeb.PageController

  setup {Req.Test, :verify_on_exit!}

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

  describe "GET /since/:days_ago" do
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

    test "adds info box if there where problems reading feeds", %{conn: conn} do
      Storage.replace([], [%Problem{reason: "Test", message: "Just a test", url: "https://a.com"}])

      conn
      |> get(~p"/since/today")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query("header a.problem-indicator")
      |> assert_only_one("1 problem", fn element, text ->
        LazyHTML.text(element) =~ text
      end)
    end
  end

  describe "GET /" do
    setup do
      old = Application.get_env(@app, @home_mod)
      Application.put_env(@app, @home_mod, home_action: "yesterday")
      on_exit(:env_cleanup, fn -> Application.put_env(@app, @home_mod, old) end)
      :ok
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

  describe "POST /refresh" do
    test "refreshes all feeds", %{conn: conn} do
      published = DateTime.now!("Etc/UTC")

      Req.Test.expect(Briefly.HttpClientMock, 2, fn conn ->
        case Plug.Conn.request_url(conn) do
          "https://a.test/rss.xml" ->
            mock_feed(conn, :rss, "https://a.test/article", DateTime.add(published, -1, :hour))

          "https://b.test/atom.xml" ->
            mock_feed(conn, :atom, "https://b.test/story", DateTime.add(published, -2, :hour))
        end
      end)

      conn
      |> post(~p"/refresh")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query("main .item a")
      |> assert_list_exactly_ordered(
        ["https://a.test/article", "https://b.test/story"],
        fn element, link ->
          LazyHTML.attribute(element, "href") == [link]
        end
      )
    end
  end

  describe "GET /problems" do
    setup do
      Storage.replace([], [
        %Problem{
          reason: "Config",
          message: "File not found at given path 'asdf/gasdf/config.yml'"
        },
        %Problem{
          reason: "Feed",
          message: "Network error fetching feed: timeout",
          url: "https://my.page/section/subscection/veryspecific.rss"
        },
        %Problem{
          reason: "Item at index 4",
          message: "Invalid date, formatted as aasdf, expected 1412a",
          url: "https://some/feedwithlongerurl.rss.xml"
        },
        %Problem{
          reason: "AssertionFailedError",
          message: "Expected a = b to hold, but didn't",
          url: "https://another.page/with/a/longer/url/than/youdexpect"
        }
      ])

      :ok
    end

    test "lists all problems encountered", %{conn: conn} do
      conn
      |> get(~p"/problems")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query("main .problem")
      |> assert_list_exactly_ordered(Enum.with_index(Storage.problems(), 1), fn element,
                                                                                {problem, i} ->
        assert LazyHTML.query(element, ".index") |> LazyHTML.text() =~ to_string(i)
        assert LazyHTML.query(element, ".reason") |> LazyHTML.text() =~ problem.reason
        assert LazyHTML.query(element, ".message") |> LazyHTML.text() =~ problem.message

        if is_nil(problem.url) do
          assert LazyHTML.query(element, ".url") |> Enum.count() == 0
        else
          assert LazyHTML.query(element, ".url") |> LazyHTML.text() =~ problem.url
        end
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

  defp mock_feed(conn, type, entry_link, entry_date) do
    content = to_feed(type, entry_link, entry_date) |> Saxy.encode!(version: "1.0")

    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.resp(200, content)
  end

  defp to_feed(:rss, entry_link, entry_date) do
    Saxy.XML.element("rss", [], [
      Saxy.XML.element("channel", [], [
        Saxy.XML.element("title", [], [Saxy.XML.characters("Mocked RSS Feed")]),
        Saxy.XML.element("item", [], [
          Saxy.XML.element("title", [], [Saxy.XML.characters("Mocked RSS Entry")]),
          Saxy.XML.element("link", [], [Saxy.XML.characters(entry_link)]),
          Saxy.XML.element("pubDate", [], [
            Saxy.XML.characters(Timex.format!(entry_date, "{RFC1123}"))
          ])
        ])
      ])
    ])
  end

  defp to_feed(:atom, entry_link, entry_date) do
    Saxy.XML.element("feed", [], [
      Saxy.XML.element("title", [], [Saxy.XML.characters("Mocked Atom Feed")]),
      Saxy.XML.element("entry", [], [
        Saxy.XML.element("title", [], [Saxy.XML.characters("Mocked Atom Entry")]),
        Saxy.XML.empty_element("link", href: entry_link),
        Saxy.XML.element("published", [], [Saxy.XML.characters(DateTime.to_iso8601(entry_date))])
      ])
    ])
  end
end
