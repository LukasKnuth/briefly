defmodule Briefly do
  @moduledoc """
  High-level integration point for the web portion of the project.
  """
  require Logger

  alias Briefly.{FeedParser, Storage, ParallelRunner, Config, HttpClient}
  alias Briefly.Models.{Problem, Item}

  def refresh(opts \\ []) do
    with {:ok, config} <- Config.load_config(opts) do
      results =
        config
        |> Enum.map(fn %Config{url: url} -> url end)
        |> ParallelRunner.load_all(fn url ->
          with {:ok, stream} <- HttpClient.stream_get(url, opts) do
            FeedParser.parse_stream(stream)
          end
        end)

      {items, problems} =
        Enum.reduce(config, {[], []}, fn config, {all_items, all_problems} ->
          case Map.get(results, config.url) do
            nil ->
              # coveralls-ignore-next-line
              problem = Problem.from_feed(config.url, "not processed")
              {all_items, [problem | all_problems]}

            {:ok, items, problems} ->
              items = Enum.map(items, &update_item(&1, config))
              problems = Enum.map(problems, &Problem.add_url(&1, config.url))
              {all_items ++ items, all_problems ++ problems}

            {:error, reason} ->
              problem = Problem.from_feed(config.url, reason)
              {all_items, [problem | all_problems]}
          end
        end)

      Logger.info("DID complete feed refresh")
      Storage.replace(Enum.reverse(items), Enum.reverse(problems))
    else
      {:error, reason} ->
        Logger.error("DID fail to read config during feed refresh")
        Storage.replace([], [Problem.from_config(reason)])
    end
  end

  defp update_item(item, config) do
    item
    |> Item.add_group(config.group)
    |> Item.maybe_override_feed(config.feed)
  end

  defdelegate list_problems, to: Storage, as: :problems

  @doc """
  Retunrs feed items from **up to** `days_ago`.
  It always uses the _beginning of the day_. If `days_ago` is `0`, only items from **today**
  are retunred. If it is `1`, items from today **and yesterday** are returned. If its `2`,
  items of the last three days are returned.

  **Raises** If the given TimeZone is not supported.
  """
  def list_items(opts) do
    opts = Keyword.validate!(opts, [:days_ago, :now, timezone: "Etc/UTC"])

    opts
    |> now!()
    |> Timex.beginning_of_day()
    |> Timex.shift(days: -Keyword.get(opts, :days_ago))
    |> Storage.items()
  end

  defp now!(opts) do
    # NOTE: Timex automatically installs its full Timezone Database
    case Keyword.fetch(opts, :now) do
      {:ok, now} -> now
      :error -> Keyword.get(opts, :timezone) |> DateTime.now!()
    end
  end
end
