defmodule BrieflyWeb.PageHTML do
  use BrieflyWeb, :html

  embed_templates "page_html/*"

  def render_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%a, %d of %b at %H:%M %Z")
  end
end
