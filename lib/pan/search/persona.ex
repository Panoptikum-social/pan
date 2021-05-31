defmodule Pan.Search.Persona do
  alias PanWeb.Persona
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias Pan.Search.Manticore
  require Logger

  def migrate() do
    Manticore.post("mode=raw&query=DROP TABLE personas", "sql")

    ("mode=raw&query=CREATE TABLE personas(name text, pid string, uri string, " <>
       "description text, long_description text, thumbnail_url string, " <>
       "image_title text, podcast_ids multi, episode_ids multi, engagements json) " <>
       "min_word_len='3' min_infix_len='3' html_strip='1' html_remove_elements = 'style, script'")
    |> Manticore.post("sql")
  end

  def preloads() do
    [:episodes, :podcasts, :thumbnails, engagements: :podcast]
  end

  def selects() do
    [
      :id,
      :name,
      :pid,
      :uri,
      :description,
      :long_description,
      :image_title,
      podcasts: :id,
      episodes: :id,
      thumbnails: [:path, :filename],
      engagements: [:persona_id, :podcast_id, :role, podcast: :title]
    ]
  end

  def batch_index() do
    Pan.Search.batch_index(
      model: Persona,
      preloads: preloads(),
      selects: selects(),
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
          episode_ids: Enum.map(persona.episodes, & &1.id),
          engagements:
            Enum.map(
              persona.engagements,
              &%{podcast_title: &1.podcast.title, podcast_id: &1.podcast_id, role: &1.role}
            )
            |> Jason.encode!()
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

  def update_index(id) do
    persona =
      from(p in Persona, where: p.id == ^id, preload: ^preloads(), select: ^selects())
      |> Repo.one()

    if persona.redirect_id do
      delete_index(id)
    else
      manticore_struct(persona)[:insert]
      |> Jason.encode!()
      |> Manticore.post("replace")
    end
  end

  def delete_index(id) do
    %{index: "personas", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete")
  end

  def delete_index_orphans() do
    persona_ids =
      from(c in Persona, select: c.id)
      |> Repo.all()

    max_persona_id = Enum.max(persona_ids)
    all_ids = Range.new(1, max_persona_id) |> Enum.to_list()
    deleted_ids = all_ids -- persona_ids

    for deleted_id <- deleted_ids, do: delete_index(deleted_id)
  end
end
