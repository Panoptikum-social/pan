defmodule PanWeb.UserFrontendView do
  use PanWeb, :view

  def title("edit_password.html", _assigns),
    do: dgettext("frontend", "Edit Password") <> " · Panoptikum"

  def title("edit.html", _assigns), do: dgettext("frontend", "Update Profile") <> " · Panoptikum"
  def title("index.html", _assigns), do: dgettext("frontend", "Users") <> " · Panoptikum"
  def title("my_data.html", _assigns), do: dgettext("frontend", "My Data") <> " · Panoptikum"

  def title("my_podcasts.html", _assigns),
    do: dgettext("frontend", "My Podcasts") <> " · Panoptikum"

  def title("my_profile.html", _assigns),
    do: dgettext("frontend", "My Profile") <> " · Panoptikum"

  def title("nan.html", _assigns), do: dgettext("frontend", "Missing user id") <> " · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"
end
