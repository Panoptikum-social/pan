defmodule Pan.Search.Podcast do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.Podcast
  require Logger

  def batch_index do
    Pan.Search.batch_index(
      model: Podcast,
      preloads: [:languages, :categories, :thumbnails],
      selects: [
        :id,
        :title,
        :description,
        :summary,
        languages: :id,
        categories: :id,
        thumbnails: [:path, :filename]
      ],
      struct_function: &manticore_struct/1
    )
  end

  def manticore_struct(podcast) do
    %{
      insert: %{
        index: "podcasts",
        id: podcast.id,
        doc: %{
          title: podcast.title || "",
          description: podcast.description || "",
          thumbnail_url: thumbnail_url(podcast),
          summary: podcast.summary || "",
          language_ids: Enum.map(podcast.languages, & &1.id),
          category_ids: Enum.map(podcast.categories, & &1.id)
        }
      }
    }
  end

  defp thumbnail_url(image) do
    if length(image.thumbnails) > 0 do
      hd(image.thumbnails).path <> hd(image.thumbnails).filename
    else
      ""
    end
  end

  def batch_reset do
    Logger.info("=== full_text reset up to 10_000 podcasts ===")

    podcast_ids =
      from(p in Podcast,
        where: p.full_text == true,
        select: p.id,
        limit: 10_000
      )
      |> Repo.all()

    from(p in Podcast, where: p.id in ^podcast_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(podcast_ids) > 0, do: batch_reset()
  end
end
