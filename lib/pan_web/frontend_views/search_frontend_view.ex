defmodule PanWeb.SearchFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML

  def format_datetime(timestamp) do
    {:ok, date_time} = DateTime.from_unix(timestamp)

    Timex.to_date(date_time)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end
end
