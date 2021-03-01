defmodule PanWeb.Api.ErrorView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "error"

  def render("404.json-api", _assigns) do
    %{
      id: "NOT_FOUND",
      title: "404 Resource not found",
      status: 404
    }
    |> JaSerializer.ErrorSerializer.format()
  end
end
