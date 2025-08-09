defmodule BrieflyTest do
  @moduledoc """
  This is an **Integration Test** that brings all separate units together.
  """
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog, only: [with_log: 1]

  alias Briefly.Storage
  alias Briefly.Models.Item

  setup {Req.Test, :verify_on_exit!}

  @fixture_path "test/fixtures/integration/"

  describe "refresh/1" do
    test "stores all items on success" do
      Req.Test.expect(Briefly.HttpClientMock, &respond_fixture(&1, "atom_success.xml"))
      Req.Test.expect(Briefly.HttpClientMock, &respond_fixture(&1, "rss_success.xml"))

      assert :ok == Briefly.refresh(mock_opts("config_success.yml"))
      assert Storage.problems() == []

      assert [
               %{group: "Test", title: "Atom Entry", feed: "Atom Feed"},
               %{group: "Test", title: "RSS Entry", feed: "RSS Feed"}
             ] = Storage.items(~U[2023-11-11 12:00:00Z])
    end

    test "adds problem if feed can't be parsed" do
      Req.Test.expect(Briefly.HttpClientMock, 2, fn conn ->
        case Plug.Conn.request_url(conn) do
          "https://a.test/rss.xml" -> Req.Test.text(conn, "not XML...")
          "https://b.test/atom.xml" -> respond_fixture(conn, "atom_success.xml")
        end
      end)

      assert :ok == Briefly.refresh(mock_opts("config_success.yml"))

      assert [%{reason: "Feed", url: "https://a.test/rss.xml"}] =
               Storage.problems()

      assert [
               %{group: "Test", title: "Atom Entry", feed: "Atom Feed"}
             ] = Storage.items(~U[2023-11-11 12:00:00Z])
    end

    test "adds problem if config can't be read" do
      {result, log} =
        with_log(fn ->
          Briefly.refresh(mock_opts("config_doesnt_exist.yml"))
        end)

      assert result == :ok
      assert log =~ "DID fail to load configuration"
      assert Storage.items() == []
      [problem] = Storage.problems()
      assert problem.reason == "Config"
      assert problem.message =~ "no such file or directory"
    end
  end

  describe "list_items" do
    test "falls back to UTC if no timezone is given" do
      now = DateTime.now!("Etc/UTC")

      Storage.replace(
        [
          %Item{date: DateTime.add(now, -1, :day), link: "itemA", title: "Mock A", feed: "Test"},
          %Item{date: DateTime.add(now, -2, :day), link: "itemB", title: "Mock B", feed: "Test"},
          %Item{date: DateTime.add(now, -3, :day), link: "itemC", title: "Mock C", feed: "Test"}
        ],
        []
      )

      assert [%{link: "itemA"}, %{link: "itemB"}] = Briefly.list_items(days_ago: 2)
    end

    test "respects given timezone when calculating cutoff" do
      # NOTE: Time is complicated. Berlin is `+2` - the plus meaning its _ahead_ of lower-value
      # timezones like Los Angeles which is `-7`. Due to the earths rotation, the new days sun
      # touches Berlin _before_ it touches Los Angeles. 
      date_time = ~N[2023-10-21 00:00:00]

      Storage.replace(
        [
          %Item{
            date: DateTime.from_naive!(date_time, "Europe/Berlin"),
            link: "itemA",
            title: "Mock A"
          }
        ],
        []
      )

      # From LA, the Berlin article was released _yesterday_
      assert Briefly.list_items(
               days_ago: 0,
               now: DateTime.from_naive!(date_time, "America/Los_Angeles")
             ) == []

      # From Sydney, the Berlin article was released _today_
      assert [%{link: "itemA"}] =
               Briefly.list_items(
                 days_ago: 0,
                 now: DateTime.from_naive!(date_time, "Australia/Sydney")
               )

      # If we include yesterday, it shows up in LA as well
      assert [%{link: "itemA"}] =
               Briefly.list_items(
                 days_ago: 1,
                 now: DateTime.from_naive!(date_time, "America/Los_Angeles")
               )
    end
  end

  defp mock_opts(config_file, opts \\ []) do
    Keyword.put_new(opts, :path, Path.join(@fixture_path, config_file))
  end

  defp respond_fixture(conn, response_file) do
    content = File.read!(Path.join(@fixture_path, response_file))

    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.resp(200, content)
  end
end
