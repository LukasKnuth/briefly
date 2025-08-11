defmodule Briefly.Models.ProblemTest do
  use ExUnit.Case, async: true

  alias Briefly.Models.Problem

  describe "from_error/1" do
    test "generates message from error" do
      error = %File.Error{action: "touch", path: "mc/hammer", reason: :eacces}
      assert %Problem{} = problem = Problem.from_error(error)

      assert Problem.message(problem) =~
               "File.Error: could not touch \"mc/hammer\": permission denied"
    end
  end

  describe "add_url/2" do
    test "overrides the `url` property" do
      problem =
        %Problem{reason: "test", message: "untouched"} |> Problem.add_url("https://a.test")

      assert Problem.message(problem) == "(https://a.test) test: untouched"
    end
  end
end
