defmodule Briefly.Config do
  @moduledoc """
  Loads user configuration from the specified YAML file.
  The configuration currently contains:

  - The list of feeds to load
  - (Optional) group name for each feed
  """
  alias YamlElixir, as: YAML

  require Logger

  defstruct url: nil, group: nil

  @type path_override :: {:path, binary()}
  @spec load_config([path_override()]) :: {:ok, [%__MODULE__{}]} | {:error, reason :: any()}
  def load_config(overrides \\ []) do
    file_path = file_path(overrides)

    file_path
    |> YAML.read_from_file()
    |> case do
      {:ok, yaml} ->
        parse_to(yaml)

      {:error, reason} ->
        Logger.error("DID fail to load configuration", file_path: file_path, reason: reason)
        {:error, reason}
    end
  end

  defp parse_to(%{"feeds" => feeds}) when is_list(feeds) do
    Enum.reduce(feeds, [], fn
      url, acc when is_binary(url) ->
        %__MODULE__{url: url} |> prepend(acc)

      %{"url" => url} = map, acc ->
        %__MODULE__{url: url, group: Map.get(map, "group")} |> prepend(acc)

      entry, acc ->
        Logger.warning("DID skip malformed config entry", entry: entry)
        acc
    end)
    |> Enum.reverse()
    |> then(&{:ok, &1})
  end

  defp parse_to(_) do
    Logger.error("DID fail to parse configuration, expected 'feeds' array at root")
    {:error, :malformed}
  end

  defp prepend(element, list) do
    [element | list]
  end

  defp file_path(overrides) do
    case Keyword.fetch(overrides, :path) do
      {:ok, path} ->
        path

      :error ->
        :briefly
        |> Application.fetch_env!(__MODULE__)
        |> Keyword.fetch!(:file_path)
    end
  end
end
