defmodule MinimalistReader.ConfigTest do
  # NOTE: no async because we capture log output.
  use ExUnit.Case

  import ExUnit.CaptureLog, only: [with_log: 1]

  alias MinimalistReader.Config

  describe "load_config/0" do
    test "loads config from valid file" do
      assert {:ok,
              [
                %Config{url: "https://lknuth.dev/writings/index.xml", group: nil},
                %Config{url: "https://feeds.bbci.co.uk/news/world/europe/rss.xml", group: "News"},
                %Config{url: "https://example.com/madeup/rss", group: nil},
                %Config{url: "https://www.theverge.com/rss/index.xml", group: "News"}
              ]} == Config.load_config(fixture_override("valid.yml"))
    end

    test "skips malformed entry and logs" do
      {result, log} =
        with_log(fn ->
          Config.load_config(fixture_override("malformed_entry.yml"))
        end)

      assert {:ok,
              [
                %Config{url: "https://lknuth.dev/writings/index.xml", group: nil}
              ]} == result

      assert log =~ "DID skip malformed config entry"
    end

    test "fails and logs if config can't be loaded" do
      {result, log} =
        with_log(fn ->
          Config.load_config(fixture_override("not_found.yml"))
        end)

      assert {:error, %YamlElixir.FileNotFoundError{}} = result
      assert log =~ "DID fail to load configuration"
    end

    test "fails and logs if config doesn't match format" do
      {result, log} =
        with_log(fn ->
          Config.load_config(fixture_override("malformed_root.yml"))
        end)

      assert {:error, :malformed} == result
      assert log =~ "DID fail to parse configuration, expected 'feeds' array at root"
    end
  end

  defp fixture_override(file_name) do
    [{:path, Path.join("test/fixtures/config/", file_name)}]
  end
end
