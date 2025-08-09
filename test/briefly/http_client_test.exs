defmodule Briefly.HttpClientTest do
  use ExUnit.Case, async: true

  alias Briefly.HttpClient

  setup {Req.Test, :verify_on_exit!}

  describe "stream_get/2" do
    test "returns body stream on 200 response" do
      Req.Test.stub(Briefly.HttpClientMock, &Req.Test.text(&1, "this works!"))

      assert {:ok, stream} = do_request()
      assert ["this works!"] == Enum.to_list(stream)
    end

    test "returns error tuple if response is not 2xx" do
      Req.Test.stub(
        Briefly.HttpClientMock,
        &Plug.Conn.send_resp(&1, 500, "internal server error")
      )

      assert {:error, %Req.Response{status: 500}} = do_request(retry: false)
    end

    test "retries request if it fails" do
      Req.Test.expect(
        Briefly.HttpClientMock,
        &Plug.Conn.send_resp(&1, 500, "internal server error")
      )

      Req.Test.expect(Briefly.HttpClientMock, &Req.Test.text(&1, "now it worked"))

      assert {:ok, stream} = do_request()
      assert ["now it worked"] == Enum.to_list(stream)
    end

    test "returns error tuple on network failure" do
      Req.Test.expect(Briefly.HttpClientMock, &Req.Test.transport_error(&1, :econnrefused))

      assert {:error, %Req.TransportError{reason: :econnrefused}} = do_request(retry: false)
    end
  end

  defp do_request(opts \\ []) do
    HttpClient.stream_get("https://test.example/feeds/rss", opts)
  end
end
