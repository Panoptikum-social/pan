defmodule PanWeb.PodcastView do
  use PanWeb, :view

  def format_for_vienna(datetime) do
    if datetime do
      datetime =
        datetime
        |> DateTime.from_naive!("Etc/UTC")
        |> Timex.Timezone.convert("Europe/Vienna")
        |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}")

      "<nobr>#{datetime}</nobr>"
    else
      "no datetime"
    end
  end
end
