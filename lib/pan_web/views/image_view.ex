defmodule PanWeb.ImageView do
  use PanWeb, :view

  def thumbnail(record) do
    [img_tag(record.path <> record.filename, width: 50)]
    |> Enum.map_join(&my_safe_to_string/1)
  end
end
