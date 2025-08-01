defmodule MinimalistReader.StorageTest do
  # NOTE: not using "async" because the GenServer has a global `name` registered
  use ExUnit.Case

  alias MinimalistReader.Models.Item
  alias MinimalistReader.Storage

  describe "replace/2" do
    test "updates items and problems in one operation" do
      items = [
        make_item("itemA", ~U[2020-10-23 14:00:00Z]),
        make_item("itemB", ~U[2020-10-23 17:00:00Z])
      ]

      problems = ["something went wrong", "something else, too"]

      assert {:noreply, %Storage{items: ^items, problems: ^problems}} =
               Storage.handle_cast({:replace, items, problems}, %Storage{})
    end

    test "does not retain previous items/problems" do
      state = %Storage{
        items: [make_item("itemA", ~U[2020-10-23 14:00:00Z])],
        problems: ["something went wrong"]
      }

      items = [make_item("itemB", ~U[2020-10-23 17:00:00Z])]
      problems = ["something went wrong", "something else, too"]

      assert {:noreply, %Storage{items: ^items, problems: ^problems}} =
               Storage.handle_cast({:replace, items, problems}, state)
    end
  end

  describe "feed/1" do
    test "returns only items after the cutoff" do
      state = %Storage{
        items: [
          make_item("itemA", ~U[2020-10-23 14:00:00Z]),
          make_item("itemB", ~U[2020-10-23 17:00:00Z])
        ]
      }

      assert {:reply, [%Item{link: "itemB"}], ^state} =
               Storage.handle_call({:feed, ~U[2020-10-23 14:30:00Z]}, nil, state)
    end

    test "sorts returned items by date" do
      state = %Storage{
        items: [
          make_item("itemA", ~U[2020-10-23 17:00:00Z]),
          make_item("itemB", ~U[2020-10-23 14:00:00Z])
        ]
      }

      assert {:reply, [%Item{link: "itemB"}, %Item{link: "itemA"}], ^state} =
               Storage.handle_call({:feed, ~U[2020-10-23 13:00:00Z]}, nil, state)
    end

    test "returns empty list if no items match" do
      state = %Storage{
        items: [
          make_item("itemA", ~U[2020-10-23 14:00:00Z]),
          make_item("itemB", ~U[2020-10-23 17:00:00Z])
        ]
      }

      assert {:reply, [], ^state} =
               Storage.handle_call({:feed, ~U[2020-10-23 18:00:00Z]}, nil, state)
    end
  end

  describe "problems/0" do
    test "returns all problems from state" do
      state = %Storage{problems: ["problemA", "problemB"]}

      assert {:reply, ["problemA", "problemB"], ^state} =
               Storage.handle_call(:problems, nil, state)
    end
  end

  defp make_item(id, date) do
    %Item{date: date, link: id, title: "Mock #{id}", feed: "Test"}
  end
end
