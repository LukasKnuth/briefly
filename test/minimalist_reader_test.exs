defmodule MinimalistReaderTest do
  @moduledoc """
  This is an **Integration Test** that brings all separate units together.
  """
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog, only: [with_log: 1]

  alias MinimalistReader.Storage
  alias MinimalistReader.Models.Item

  setup {Req.Test, :verify_on_exit!}

  @fixture_path "test/fixtures/integration/"

  describe "refresh/1" do
    test "stores all items on success" do
      Req.Test.expect(__MODULE__, &respond_fixture(&1, "atom_success.xml"))
      Req.Test.expect(__MODULE__, &respond_fixture(&1, "rss_success.xml"))

      assert :ok == MinimalistReader.refresh(mock_opts("config_success.yml"))
      assert Storage.problems() == []

      assert [
               %{group: "Test", title: "Atom Entry", feed: "Atom Feed"},
               %{group: "Test", title: "RSS Entry", feed: "RSS Feed"}
             ] = Storage.items(~U[2023-11-11 12:00:00Z])
    end

    test "adds problem if feed can't be parsed" do
      Req.Test.expect(__MODULE__, 2, fn conn ->
        case Plug.Conn.request_url(conn) do
          "https://a.test/rss.xml" -> Req.Test.text(conn, "not XML...")
          "https://b.test/atom.xml" -> respond_fixture(conn, "atom_success.xml")
        end
      end)

      assert :ok == MinimalistReader.refresh(mock_opts("config_success.yml"))

      assert [%{reason: "Feed", url: "https://a.test/rss.xml"}] =
               Storage.problems()

      assert [
               %{group: "Test", title: "Atom Entry", feed: "Atom Feed"}
             ] = Storage.items(~U[2023-11-11 12:00:00Z])
    end

    test "adds problem if config can't be read" do
      {result, log} =
        with_log(fn ->
          MinimalistReader.refresh(mock_opts("config_doesnt_exist.yml"))
        end)

      assert result == :ok
      assert log =~ "DID fail to load configuration"
      assert Storage.items() == []
      [problem] = Storage.problems()
      assert problem.reason == "Config"
      assert problem.message =~ "no such file or directory"
    end
  end

  defp mock_opts(config_file, opts \\ []) do
    opts
    |> Keyword.put_new(:plug, {Req.Test, __MODULE__})
    |> Keyword.put_new(:path, Path.join(@fixture_path, config_file))
  end

  defp respond_fixture(conn, response_file) do
    content = File.read!(Path.join(@fixture_path, response_file))

    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.resp(200, content)
  end
end
