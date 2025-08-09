defmodule BrieflyWeb.Layouts do
  use BrieflyWeb, :html

  embed_templates "layouts/*"

  def days_ago do
    [
      {"today", "Today"},
      {"yesterday", "Yesterday"},
      {"3d", "Last 3 days"},
      {"5d", "Last 5 days"},
      {"7d", "Last week"}
    ]
  end

  def problem_label do
    Briefly.list_problems()
    |> length()
    |> case do
      0 -> nil
      1 -> "⚠️ 1 problem"
      n -> "⚠️ #{n} problems"
    end
  end
end
