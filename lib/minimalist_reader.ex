defmodule MinimalistReader do
  @moduledoc """
  High-level integration point for the web portion of the project.
  """
  alias MinimalistReader.{FeedParser, Storage, Loader, Config, HttpClient}
  alias MinimalistReader.Models.{Problem, Item}

  def refresh(opts \\ []) do
    with {:ok, config} <- Config.load_config(opts) do
      results =
        config
        |> Enum.map(fn %Config{url: url} -> url end)
        |> Loader.load_all(fn url ->
          with {:ok, stream} <- HttpClient.stream_get(url, opts) do
            FeedParser.parse_stream(stream)
          end
        end)

      {items, problems} =
        Enum.reduce(config, {[], []}, fn %Config{url: url, group: group},
                                         {all_items, all_problems} ->
          case Map.get(results, url) do
            nil ->
              # coveralls-ignore-next-line
              problem = Problem.from_feed(url, "not processed")
              {all_items, [problem | all_problems]}

            {:ok, items, problems} ->
              items = Enum.map(items, &Item.add_group(&1, group))
              problems = Enum.map(problems, &Problem.add_url(&1, url))
              {all_items ++ items, all_problems ++ problems}

            {:error, reason} ->
              problem = Problem.from_feed(url, reason)
              {all_items, [problem | all_problems]}
          end
        end)

      Storage.replace(Enum.reverse(items), Enum.reverse(problems))
    else
      {:error, reason} ->
        Storage.replace([], [Problem.from_config(reason)])
    end
  end

  defdelegate list_problems, to: Storage, as: :problems
end
