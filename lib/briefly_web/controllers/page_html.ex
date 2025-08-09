defmodule BrieflyWeb.PageHTML do
  use BrieflyWeb, :html

  embed_templates "page_html/*"

  def render_date(%DateTime{} = dt) do
    Briefly.user_timezone()
    |> then(&Timex.Timezone.convert(dt, &1))
    |> Calendar.strftime("%a, %d of %b at %H:%M")
  end
end
