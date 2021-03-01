defmodule PanWeb.Api.InvoiceView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "invoice"

  attributes([:filename, :content_type, :inserted_at])
end
