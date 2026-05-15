defmodule PanWeb.ImageView do
  use PanWeb, :view

  def thumbnail(record) do
    ~s(<img src="#{record.path <> record.filename}" width="50" />)
  end
end
