defmodule MinimalistReader.Models.Problem do
  @moduledoc """
  Describes a single problem encountered while loading/parsing items.
  """
  defstruct reason: nil, message: nil, metadata: %{}

  def from_error(%type{} = error) do
    %__MODULE__{
      reason: as_text(type),
      message: as_text(error),
      metadata: %{original: error}
    }
  end

  def from_item(feed_index, reason) do
    %__MODULE__{
      reason: "Item at index #{feed_index}",
      message: as_text(reason),
      metadata: %{index: feed_index}
    }
  end

  defp as_text(reason) when is_binary(reason), do: reason
  defp as_text(reason) when is_exception(reason), do: Exception.message(reason)
  defp as_text(reason) when is_atom(reason), do: to_string(reason)
  defp as_text(reason), do: inspect(reason)

  def message(%__MODULE__{reason: reason, message: message}) do
    "#{reason}: #{message}"
  end
end
