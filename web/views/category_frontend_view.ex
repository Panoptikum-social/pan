defmodule Pan.CategoryFrontendView do
  use Pan.Web, :view

  def panel_cycle(counter) do
    Enum.at(["panel-default", "panel-info", "panel-danger",
             "panel-warning", "panel-primary", "panel-success"], rem(counter, 6))
  end

  def btn_cycle(counter) do
    Enum.at(["btn-default", "btn-info", "btn-danger",
             "btn-warning", "btn-primary", "btn-success"], rem(counter, 6))
  end

  def color_cycle(counter) do
    Enum.at(["666", "fff", "fff",
             "fff", "fff", "fff"], rem(counter, 6))
  end
end
