defmodule PanWeb.UserFrontendView do
  use PanWeb, :view
  import Pan.Parser.MyDateTime, only: [now: 0, in_the_future?: 1]

  def pro(user), do: in_the_future?(user.pro_until)

  def pro_days_left(user) do
    Timex.diff(user.pro_until, now(), :days)
  end

  def alert_class(user) do
    cond do
      pro_days_left(user) > 30 -> "success"
      pro_days_left(user) > 7 -> "warning"
      pro_days_left(user) < 7 -> "danger"
    end
  end

  def format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end
end
