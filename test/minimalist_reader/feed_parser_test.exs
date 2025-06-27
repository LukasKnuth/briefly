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

  @test_atom """
  <?xml version="1.0" encoding="utf-8"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
  <title>Example Feed</title>
  <subtitle>A subtitle.</subtitle>
  <link href="http://example.org/feed/" rel="self" />
  <link href="http://example.org/" />
  <id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>
  <updated>2003-12-13T18:30:02Z</updated>
  <entry>
  <title>Atom-Powered Robots Run Amok</title>
  <link href="http://example.org/2003/12/13/atom03" />
  <link rel="alternate" type="text/html" href="http://example.org/2003/12/13/atom03.html"/>
  <link rel="edit" href="http://example.org/2003/12/13/atom03/edit"/>
  <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
  <published>2003-11-09T17:23:02Z</published>
  <updated>2003-12-13T18:30:02Z</updated>
  <summary>Some text.</summary>
  <content type="xhtml">
  	<div xmlns="http://www.w3.org/1999/xhtml">
  		<p>This is the entry content.</p>
  	</div>
  </content>
  <author>
  	<name>John Doe</name>
  	<email>johndoe@example.com</email>
  </author>
  </entry>
  </feed>
  """

  describe "parse_stream/1" do
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

    test "parses Atom formatted feed" do
      res = @test_atom |> String.splitter("\n") |> FeedParser.parse_stream()

      assert {:ok, [item]} = res

      assert item == %Item{
               feed: "Example Feed",
               title: "Atom-Powered Robots Run Amok",
               link: "http://example.org/2003/12/13/atom03.html",
               date: ~U[2003-11-09 17:23:02Z]
             }
    end
  end
end
