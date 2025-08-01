defmodule MinimalistReader.HttpClientTest do
  use ExUnit.Case, async: true

  alias MinimalistReader.HttpClient

  setup {Req.Test, :verify_on_exit!}

  describe "stream_get/2" do
    test "returns body stream on 200 response" do
      Req.Test.stub(__MODULE__, &Req.Test.text(&1, "this works!"))

      assert {:ok, stream} = mock_request()
      assert ["this works!"] == Enum.to_list(stream)
    end

    test "returns error tuple if response is not 2xx" do
      Req.Test.stub(__MODULE__, &Plug.Conn.send_resp(&1, 500, "internal server error"))

      assert {:error, %Req.Response{status: 500}} = mock_request(retry: false)
    end

    test "retries request if it fails" do
      Req.Test.expect(__MODULE__, &Plug.Conn.send_resp(&1, 500, "internal server error"))
      Req.Test.expect(__MODULE__, &Req.Test.text(&1, "now it worked"))

      assert {:ok, stream} = mock_request()
      assert ["now it worked"] == Enum.to_list(stream)
    end

    test "returns error tuple on network failure" do
      Req.Test.expect(__MODULE__, &Req.Test.transport_error(&1, :econnrefused))

      assert {:error, %Req.TransportError{reason: :econnrefused}} = mock_request(retry: false)
    end
  end

  defp mock_request(opts \\ []) do
    opts = Keyword.put(opts, :plug, {Req.Test, __MODULE__})
    HttpClient.stream_get("https://test.example/feeds/rss", opts)
  end
end
