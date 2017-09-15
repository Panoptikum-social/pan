defmodule PanWeb.ErrorApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "error"
end