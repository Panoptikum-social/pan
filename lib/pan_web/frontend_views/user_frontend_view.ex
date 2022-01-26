defmodule PanWeb.UserFrontendView do
  use PanWeb, :view
  import Pan.Parser.MyDateTime, only: [now: 0]

  def pro(user) do
    user.pro_until != nil && NaiveDateTime.compare(user.pro_until, now()) == :gt
  end

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
