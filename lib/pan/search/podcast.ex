defmodule Pan.Search.Podcast do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.Podcast
  alias Pan.Search.Manticore
  require Logger

  def migrate() do
    Manticore.post("mode=raw&query=DROP TABLE podcasts", "sql")

    ("mode=raw&query=CREATE TABLE podcasts(title text, description text, thumbnail_url string, " <>
       "summary text, image_title string, " <>
       "language_ids multi, category_ids multi, contributor_ids multi, " <>
       "languages json, categories json, engagements json) " <>
       "min_infix_len='2' html_strip='1' html_remove_elements = 'style, script'")
    |> Manticore.post("sql")
  end

  def preloads() do
    [:languages, :categories, :thumbnails, :contributors, engagements: :persona]
  end

  def selects() do
    [
      :id,
      :blocked,
      :title,
      :description,
      :summary,
      :image_title,
      languages: [:id, :shortcode, :name, :emoji],
      categories: [:id, :title],
      contributors: :id,
      thumbnails: [:path, :filename],
      engagements: [:podcast_id, :persona_id, :role, persona: :name]
    ]
  end

  def batch_index() do
    Pan.Search.batch_index(
      model: Podcast,
      preloads: preloads(),
      selects: selects(),
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
          image_title: podcast.image_title || "",
          language_ids: Enum.map(podcast.languages, & &1.id),
          category_ids: Enum.map(podcast.categories, & &1.id),
          contributor_ids: Enum.map(podcast.contributors, & &1.id),
          engagements:
            Enum.map(
              podcast.engagements,
              &%{persona_name: &1.persona.name, persona_id: &1.persona_id, role: &1.role}
            )
            |> Jason.encode!(),
          languages:
            Enum.map(
              podcast.languages,
              &%{id: &1.id, shortcode: &1.shortcode, name: &1.name, emoji: &1.emoji}
            )
            |> Jason.encode!(),
          categories:
            Enum.map(podcast.categories, &%{id: &1.id, title: &1.title}) |> Jason.encode!()
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

  def update_index(id) do
    podcast =
      from(p in Podcast, where: p.id == ^id, preload: ^preloads(), select: ^selects())
      |> Repo.one()

    if podcast.blocked do
      delete_index(id)
    else
      manticore_struct(podcast)[:insert]
      |> Jason.encode!()
      |> Manticore.post("replace")
    end
  end

  def delete_index(id) do
    %{index: "podcasts", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete")
  end

  def delete_index_orphans() do
    podcast_ids =
      from(c in Podcast, select: c.id)
      |> Repo.all()

    max_podcast_id = Enum.max(podcast_ids)
    all_ids = Range.new(1, max_podcast_id) |> Enum.to_list()
    deleted_ids = all_ids -- podcast_ids

    for deleted_id <- deleted_ids, do: delete_index(deleted_id)
  end
end
