defmodule MinimalistReader.LoaderTest do
  use ExUnit.Case, async: true

  alias MinimalistReader.Loader

  @opts [mod_fun: {__MODULE__, :mock}]

  describe "load_all/2" do
    test "returns map with all results" do
      assert %{"works" => {:ok, :yay}, "breaks" => {:error, :nay}} ==
               Loader.load_all(["works", "breaks"], @opts)
    end

    test "captures an exception and returns it" do
      assert %{"works" => {:ok, :yay}, "raise" => {:error, %IO.StreamError{}}} ==
               Loader.load_all(["raise", "works"], @opts)
    end

    test "captures a timeout and returns it" do
      assert %{"works" => {:ok, :yay}, "timeout" => {:error, :timeout}} ==
               Loader.load_all(["works", "timeout"], Keyword.put(@opts, :timeout, 50))
    end
  end

  def mock("works"), do: {:ok, :yay}
  def mock("breaks"), do: {:error, :nay}
  def mock("raise"), do: raise(IO.StreamError)
  def mock("timeout"), do: Process.sleep(100)
end
