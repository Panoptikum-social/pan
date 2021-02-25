defmodule PanWeb.PageFrontendView do
  use PanWeb, :view

  def get_shade(color) do
    color
    |> Atom.to_string()
    |> String.split("-")
    |> List.last()
    |> String.to_integer()
  end
end
