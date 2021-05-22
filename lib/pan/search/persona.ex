defmodule Pan.Search.Persona do
  alias PanWeb.Persona
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  require Logger

  def create_index() do
    # index personas {
    #   type = rt
    #   path = /var/lib/manticore/data/personas
    #   rt_field = name
    #   rt_attr_string = pid
    #   rt_attr_string = uri
    #   rt_field = description
    #   rt_field = long_description
    #   rt_attr_string = thumbnail_url
    #   rt_field = image_title
    #   rt_attr_multi = podcast_ids
    #   rt_attr_multi = episode_ids
    #   min_word_len = 3
    #   min_infix_len = 3
    #   html_strip = 1
    #   html_remove_elements = 'style, script'
    #   stored_fields='name, description, long_description, image_title'
    #   charset_table = non_cjk
    # }
  end

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
