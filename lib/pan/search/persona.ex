defmodule Pan.Search.Persona do
  alias PanWeb.Persona
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  require Logger

  def batch_index() do
    Pan.Search.batch_index(
      model: Persona,
      preloads: [:episodes, :podcasts, :thumbnails],
      selects: [
        :id,
        :name,
        :pid,
        :uri,
        :description,
        :long_description,
        :image_title,
        podcasts: :id,
        episodes: :id,
        thumbnails: [:path, :filename]
      ],
      struct_function: &manticore_struct/1
    )
  end

  def manticore_struct(persona) do
    %{
      insert: %{
        index: "personas",
        id: persona.id,
        doc: %{
          name: persona.name || "",
          pid: persona.pid || "",
          uri: persona.uri || "",
          description: persona.description || "",
          long_description: persona.long_description || "",
          thumbnail_url: thumbnail_url(persona),
          image_title: persona.image_title || "",
          podcast_ids: Enum.map(persona.podcasts, & &1.id),
          episode_ids: Enum.map(persona.episodes, & &1.id)
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
    Logger.info("=== full_text reset up to 10_000 personas ===")

    persona_ids =
      from(p in Persona,
        where: p.full_text == true,
        select: p.id,
        limit: 10_000
      )
      |> Repo.all()

    from(p in Persona, where: p.id in ^persona_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(persona_ids) > 0, do: batch_reset()
  end
end
