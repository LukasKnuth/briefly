defmodule Briefly.Storage do
  @moduledoc """
  An in-memory storage for `Briefly.Models.Item` parsed from
  feeds and any problems that occurred during the parsing.
  """
  use GenServer

  alias Briefly.Models.Item

  defstruct items: [], problems: [], last_updated: nil

  # coveralls-ignore-start
  ##### CLIENT ####
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def replace(items, problems) when is_list(items) and is_list(problems),
    do: GenServer.cast(__MODULE__, {:replace, items, problems})

  def items, do: GenServer.call(__MODULE__, :all_items)
  def items(%DateTime{} = cutoff), do: GenServer.call(__MODULE__, {:items, cutoff})
  def problems, do: GenServer.call(__MODULE__, :problems)
  def last_updated, do: GenServer.call(__MODULE__, :last_updated)

  ##### SERVER ####
  def init(_opts), do: {:ok, %__MODULE__{}}
  # coveralls-ignore-stop

  def handle_cast({:replace, items, problems}, state) do
    now = Briefly.user_timezone() |> DateTime.now!()
    {:noreply, %{state | items: items, problems: problems, last_updated: now}}
  end

  def handle_call(:all_items, _from, %__MODULE__{items: items} = state) do
    {:reply, newest_first(items), state}
  end

  def handle_call({:items, cutoff}, _from, %__MODULE__{items: items} = state) do
    items
    |> Enum.filter(fn %Item{date: released} -> DateTime.after?(released, cutoff) end)
    |> newest_first()
    |> then(&{:reply, &1, state})
  end

  def handle_call(:problems, _from, %__MODULE__{problems: problems} = state) do
    {:reply, problems, state}
  end

  def handle_call(:last_updated, _from, %__MODULE__{last_updated: last_updated} = state) do
    {:reply, last_updated, state}
  end

  defp newest_first(items), do: Enum.sort_by(items, & &1.date, {:desc, DateTime})
end
