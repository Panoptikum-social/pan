defmodule PanWeb.ImageView do
  use Pan.Web, :view

  def render("datatable.json", %{
        images: images,
        draw: draw,
        records_total: records_total,
        records_filtered: records_filtered
      }) do
    %{
      draw: draw,
      recordsTotal: records_total,
      recordsFiltered: records_filtered,
      data: Enum.map(images, &image_json/1)
    }
  end

  def image_json(image) do
    %{
      id: image.id,
      filename: image.filename,
      content_type: image.content_type,
      path: image.path,
      podcast_id: image.podcast_id,
      episode_id: image.episode_id,
      persona_id: image.persona_id,
      thumbnail: thumbnail(image),
      actions: datatable_actions(image.id, &image_path/3)
    }
  end

  def thumbnail(record) do
    [img_tag(record.path <> record.filename, width: 50)]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end
end
