defmodule Briefly.ApplicationTest do
  use ExUnit.Case, async: true

  describe "start/2" do
    setup do
      old = Application.get_env(:briefly, Briefly)
      on_exit(:env_cleanup, fn -> Application.put_env(:briefly, Briefly, old) end)
      :ok
    end

    test "returns {:error, reason} if configured timezone is invalid" do
      Application.put_env(:briefly, Briefly, timezone: "Europe/Börlin")
      assert {:error, msg} = Briefly.Application.start(nil, [])
      assert msg =~ "timezone 'Europe/Börlin' is invalid"
    end
  end
end
