defmodule MinimalistReader.FeedParserTest do
  use ExUnit.Case, async: true

  alias MinimalistReader.FeedParser
  alias MinimalistReader.Models.Item

  @test_xml """
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

  describe "parse_stream/1" do
    test "parses RSS formatted feed" do
      res = @test_xml |> String.splitter("\n") |> FeedParser.parse_stream()

      assert {:ok, [item]} = res

      assert item == %Item{
               feed: "RSS Title",
               title: "Example entry",
               link: "http://www.example.com/blog/post/1",
               pub_date: ~U[2009-09-06 16:20:00Z]
             }
    end
  end
end
