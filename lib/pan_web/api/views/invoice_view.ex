defmodule PanWeb.Api.InvoiceView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "invoice"

  attributes [:filename, :content_type, :inserted_at]
end