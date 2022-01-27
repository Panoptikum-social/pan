defmodule PanWeb.UserFrontendView do
  use PanWeb, :view
  import Pan.Parser.MyDateTime, only: [now: 0, in_the_future?: 1, time_diff: 3]

  def title("edit_password.html", _assigns), do: "Edit Password · Panoptikum"
  def title("edit.html", _assigns), do: "Update Profile · Panoptikum"
  def title("index.html", _assigns), do: "Users · Panoptikum"
  def title("my_data.html", _assigns), do: "My Data · Panoptikum"
  def title("my_podcasts.html", _assigns), do: "My Podcasts · Panoptikum"
  def title("my_profile.html", _assigns), do: "My Profile · Panoptikum"
  def title("nan.html", _assigns), do: "Missing user id · Panoptikum"
  def title("payment_info.html", _assigns), do: "Payment Information · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"

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
