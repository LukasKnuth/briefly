defmodule MinimalistReader.Loader do
  @moduledoc """
  A multithreaded loader component to fetch multiple feeds.
  """
  alias MinimalistReader.FeedParser

  @default_opts [{:timeout, :timer.seconds(2)}, :mod_fun]

  @type url :: binary()
  @spec load_all([url]) :: %{
          url => {:ok, FeedParser.item(), FeedParser.problem()} | {:error, any()}
        }
  def load_all(urls, opts \\ []) when is_list(urls) do
    opts = Keyword.validate!(opts, @default_opts)

    MinimalistReader.TaskSupervisor
    |> Task.Supervisor.async_stream_nolink(
      urls,
      __MODULE__,
      :do_work,
      [opts],
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

  def do_work(url, opts) do
    {module, function} = Keyword.fetch!(opts, :mod_fun)
    result = apply(module, function, [url])
    {url, result}
  rescue
    error -> {url, {:error, error}}
  end
end
