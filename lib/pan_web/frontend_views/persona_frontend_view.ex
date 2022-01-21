defmodule PanWeb.PersonaFrontendView do
  use PanWeb, :view

  def pro(user) do
    PanWeb.UserFrontendView.pro(user)
  end

  def format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end
end
