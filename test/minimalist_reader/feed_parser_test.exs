defmodule MinimalistReader.FeedParserTest do
  use ExUnit.Case, async: true

  alias MinimalistReader.FeedParser
  alias MinimalistReader.Models.Item

  @test_rss """
  <?xml version="1.0" encoding="UTF-8" ?>
  <rss version="2.0">
  <channel>
  <title>RSS Title</title>
  <description>This is an example of an RSS feed</description>
  <link>http://www.example.com/main.html</link>
  <copyright>2020 Example.com All rights reserved</copyright>
  <lastBuildDate>Mon, 6 Sep 2010 00:01:00 +0000</lastBuildDate>
  <pubDate>Sun, 6 Sep 2009 16:20:00 +0000</pubDate>
  <ttl>1800</ttl>
  <item>
  <title>Example entry</title>
  <description>Here is some text containing an interesting description.</description>
  <link>http://www.example.com/blog/post/1</link>
  <guid isPermaLink="false">7bd204c6-1655-4c27-aeee-53f933c5395f</guid>
  <pubDate>Sun, 6 Sep 2009 16:20:00 +0000</pubDate>
  </item>
  </channel>
  </rss>
  """

  describe "parse_stream/1 for RSS" do
    test "parses RSS formatted feed" do
      res = @test_rss |> String.splitter("\n") |> FeedParser.parse_stream()

      assert {:ok, [item]} = res

      assert item == %Item{
               feed: "RSS Title",
               title: "Example entry",
               link: "http://www.example.com/blog/post/1",
               date: ~U[2009-09-06 16:20:00Z]
             }
    end
  end

  describe "parse_stream/1 for Atom" do
    test "parses valid sample feed" do
      res = FeedParser.parse_stream(load_fixture!("atom/valid_small.xml"))

      assert {:ok, [item]} = res

      assert item == %Item{
               feed: "Example Feed",
               title: "Atom-Powered Robots Run Amok",
               link: "http://example.org/2003/12/13/atom03.html",
               date: ~U[2003-11-09 17:23:02Z]
             }
    end

    test "errors if entry has malformed date" do
      res = FeedParser.parse_stream(load_fixture!("atom/malformed_date.xml"))

      assert {:error,
              %Saxy.ParseError{reason: {:bad_return, {:end_element, {:error, :invalid_format}}}}} =
               res
    end

    test "errors if entry has malformed link" do
      res = FeedParser.parse_stream(load_fixture!("atom/malformed_link.xml"))

      assert {:error,
              %Saxy.ParseError{reason: {:bad_return, {:end_element, {:error, :invalid_format}}}}} =
               res
    end

    test "falls back to `updated` if item has no `published` date" do
      res = FeedParser.parse_stream(load_fixture!("atom/fallback_entries.xml"))

      assert {:ok, [item, _]} = res

      assert item == %Item{
               feed: "Fixture",
               title: "Only updated",
               link: "http://example.org/2003/12/13/atom03",
               date: ~U[2013-12-19 15:13:42Z]
             }
    end

    test "falls back to `rel=alternate` link if non without `rel` are present" do
      res = FeedParser.parse_stream(load_fixture!("atom/fallback_entries.xml"))

      assert {:ok, [_, item]} = res

      assert item == %Item{
               feed: "Fixture",
               title: "Multiple Links",
               link: "http://example.org/2003/12/13/atom03.html",
               date: ~U[2003-11-09 17:23:02Z]
             }
    end

    test "skips entries missing required fields" do
      res = FeedParser.parse_stream(load_fixture!("atom/incomplete_entries.xml"))

      assert {:ok, []} = res
    end
  end

  defp load_fixture!(path) do
    File.stream!(Path.join("test/fixtures", path))
  end
end
