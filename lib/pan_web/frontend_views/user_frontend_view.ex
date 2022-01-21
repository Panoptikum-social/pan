defmodule PanWeb.UserFrontendView do
  use PanWeb, :view
  import NaiveDateTime

  def pro(user) do
    user.pro_until != nil && compare(user.pro_until, utc_now()) == :gt
  end

  def pro_days_left(user) do
    Timex.diff(user.pro_until, Timex.now(), :days)
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
