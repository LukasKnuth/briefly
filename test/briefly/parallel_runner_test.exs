defmodule Briefly.ParallelRunnerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog, only: [with_log: 1]

  alias Briefly.ParallelRunner

  describe "load_all/2" do
    test "returns map with all results" do
      assert %{"works" => {:ok, :yay}, "breaks" => {:error, :nay}} ==
               ParallelRunner.load_all(["works", "breaks"], &mock/1)
    end

    test "captures an exception and returns it" do
      {result, log} =
        with_log(fn -> ParallelRunner.load_all(["raise", "works"], &mock/1) end)

      assert %{"works" => {:ok, :yay}, "raise" => {:error, %IO.StreamError{}}} == result
      assert log =~ ~r/RESCUED error in Task.*(IO.StreamError)/
    end

    test "captures a timeout and returns it" do
      assert %{"works" => {:ok, :yay}, "timeout" => {:error, :timeout}} ==
               ParallelRunner.load_all(["works", "timeout"], &mock/1, timeout: 50)
    end
  end

  def mock("works"), do: {:ok, :yay}
  def mock("breaks"), do: {:error, :nay}
  def mock("raise"), do: raise(IO.StreamError)
  def mock("timeout"), do: Process.sleep(100)
end
