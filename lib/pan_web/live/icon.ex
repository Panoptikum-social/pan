defmodule PanWeb.Live.Icon do
  use PanWeb, :view

  def to_string(name), do: to_string(name, %{class: "h-6 w-6 inline"})

  def to_string(name, assigns) do
    Phoenix.View.render_to_string(PanWeb.Live.Icon, "#{name}.html", assigns)
  end
end
