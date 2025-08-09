defmodule Briefly.ParallelRunner do
  @moduledoc """
  A multithreaded loader component to fetch multiple feeds.
  """
  alias Briefly.FeedParser

  @default_opts [{:timeout, :timer.seconds(2)}]

  @type url :: binary()
  @spec load_all([url], (url -> any())) :: %{
          url => {:ok, FeedParser.item(), FeedParser.problem()} | {:error, any()}
        }
  def load_all(urls, fun, opts \\ []) when is_list(urls) and is_function(fun, 1) do
    opts = Keyword.validate!(opts, @default_opts)

    Briefly.TaskSupervisor
    |> Task.Supervisor.async_stream_nolink(
      urls,
      &do_work(&1, fun),
      ordered: false,
      timeout: Keyword.fetch!(opts, :timeout),
      on_timeout: :kill_task,
      zip_input_on_exit: true
    )
    |> Enum.reduce(%{}, fn
      {:ok, {url, result}}, map ->
        Map.put(map, url, result)

      {:exit, {url, reason}}, map ->
        Map.put(map, url, {:error, reason})
    end)
  end

  def do_work(url, fun) do
    result = fun.(url)
    {url, result}
  rescue
    error -> {url, {:error, error}}
  end
end
