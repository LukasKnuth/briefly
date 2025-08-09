defmodule Briefly.FeedParserTest do
  use ExUnit.Case, async: true

  alias Briefly.Models.Problem
  alias Briefly.FeedParser
  alias Briefly.Models.Item

  describe "parse_stream/1 for RSS" do
    test "INTEGRATION live feed" do
      resp = Req.get!("https://feeds.bbci.co.uk/news/world/europe/rss.xml", into: :self)
      res = FeedParser.parse_stream(resp.body)

      assert {:ok, results, []} = res
      assert length(results) > 0
    end

    test "parses RSS formatted feed" do
      res = FeedParser.parse_stream(load_fixture!("rss/valid_small.xml"))

      assert {:ok, [item], []} = res

      assert item == %Item{
               feed: "RSS Title",
               title: "Example entry",
               link: "http://www.example.com/blog/post/1",
               date: ~U[2009-09-06 16:20:00Z]
             }
    end

    test "errors if entry has malformed date" do
      res = FeedParser.parse_stream(load_fixture!("rss/malformed_date.xml"))

      assert {:ok, [], [%Problem{} = problem]} = res
      assert problem.reason =~ "index 0"
      assert problem.message =~ "weekday abbreviation"
    end

    test "skips entries missing required fields" do
      res = FeedParser.parse_stream(load_fixture!("rss/incomplete_entries.xml"))

      assert {:ok, [], problems} = res

      Enum.with_index(problems)
      |> Enum.each(fn {%Problem{reason: reason, message: message}, idx} ->
        assert reason =~ "index #{idx}"
        assert message == "missing required fields"
      end)
    end
  end

  describe "parse_stream/1 for Atom" do
    test "INTEGRATION live feed" do
      resp = Req.get!("https://www.theverge.com/rss/index.xml", into: :self)
      res = FeedParser.parse_stream(resp.body)

      assert {:ok, results, []} = res
      assert length(results) > 0
    end

    test "parses valid sample feed" do
      res = FeedParser.parse_stream(load_fixture!("atom/valid_small.xml"))

      assert {:ok, [item], []} = res

      assert item == %Item{
               feed: "Example Feed",
               title: "Atom-Powered Robots Run Amok",
               link: "http://example.org/2003/12/13/atom03.html",
               date: ~U[2003-11-09 17:23:02Z]
             }
    end

    test "errors if entry has malformed date" do
      res = FeedParser.parse_stream(load_fixture!("atom/malformed_date.xml"))

      assert {:ok, [], [%Problem{} = problem]} = res
      assert problem.reason =~ "index 0"
      assert problem.message =~ "invalid date format"
    end

    test "errors if entry has malformed link" do
      res = FeedParser.parse_stream(load_fixture!("atom/malformed_link.xml"))

      assert {:ok, [], [%Problem{} = first, %Problem{} = second]} = res
      # Two errors for the same item!
      assert first.reason =~ "index 0"
      assert first.message =~ "link missing"
      assert second.reason =~ "index 0"
      assert second.message =~ "missing required fields"
    end

    test "falls back to `updated` if item has no `published` date" do
      res = FeedParser.parse_stream(load_fixture!("atom/fallback_entries.xml"))

      assert {:ok, [item, _], []} = res

      assert item == %Item{
               feed: "Fixture",
               title: "Only updated",
               link: "http://example.org/2003/12/13/atom03",
               date: ~U[2013-12-19 15:13:42Z]
             }
    end

    test "falls back to `rel=alternate` link if non without `rel` are present" do
      res = FeedParser.parse_stream(load_fixture!("atom/fallback_entries.xml"))

      assert {:ok, [_, item], []} = res

      assert item == %Item{
               feed: "Fixture",
               title: "Multiple Links",
               link: "http://example.org/2003/12/13/atom03.html",
               date: ~U[2003-11-09 17:23:02Z]
             }
    end

    test "skips entries missing required fields" do
      res = FeedParser.parse_stream(load_fixture!("atom/incomplete_entries.xml"))

      assert {:ok, [], problems} = res

      Enum.with_index(problems)
      |> Enum.each(fn {%Problem{reason: reason, message: message}, idx} ->
        assert reason =~ "index #{idx}"
        assert message == "missing required fields"
      end)
    end
  end

  defp load_fixture!(path) do
    File.stream!(Path.join("test/fixtures", path))
  end
end
