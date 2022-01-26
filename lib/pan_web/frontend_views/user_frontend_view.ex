defmodule PanWeb.UserFrontendView do
  use PanWeb, :view
  import Pan.Parser.MyDateTime, only: [now: 0, in_the_future?: 1, time_diff: 3]

  def pro(user), do: in_the_future?(user.pro_until)

  def pro_days_left(user) do
    time_diff(user.pro_until, now(), :days)
  end

  def alert_class(user) do
    cond do
      pro_days_left(user) > 30 -> "success"
      pro_days_left(user) > 7 -> "warning"
      pro_days_left(user) < 7 -> "danger"
    end
  end
end
