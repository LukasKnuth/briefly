defmodule MinimalistReaderWeb.Layouts do
  use MinimalistReaderWeb, :html

  embed_templates "layouts/*"

  def days_ago do
    # TODO use translations for theses (and everywhere else...)
    [
      {"today", "Today"},
      {"yesterday", "Yesterday"},
      {"3d", "Last 3 days"},
      {"5d", "Last 5 days"},
      {"7d", "Last week"}
    ]
  end
end
