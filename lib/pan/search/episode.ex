defmodule Pan.Search.Episode do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.Episode
  alias Pan.Search.Manticore
  require Logger

  def migrate() do
    Manticore.post("mode=raw&query=DROP TABLE episodes", "sql")

    ("mode=raw&query=CREATE TABLE episodes(title text, subtitle text, description text, " <>
       "summary text, shownotes text, inserted_at timestamp, " <>
       "podcast_id int, language_ids multi, category_ids multi, gig_ids multi," <>
       "podcast json, languages json, categories json, gigs json) " <>
       "min_infix_len='2' html_strip='1' html_remove_elements = 'style, script'")
    |> Manticore.post("sql")
  end

  def preloads() do
    [gigs: :persona, podcast: [:languages, :categories]]
  end

  def selects() do
    [
      :id,
      :title,
      :subtitle,
      :description,
      :summary,
      :shownotes,
      :inserted_at,
      :podcast_id,
      podcast: [
        :id,
        :blocked,
        :title,
        languages: [:id, :shortcode, :emoji, :name],
        categories: [:id, :title]
      ],
      gigs: [:id, :episode_id, :persona_id, :role, persona: :name]
    ]
  end

  def batch_index() do
    Pan.Search.batch_index(
      model: Episode,
      preloads: preloads(),
      selects: selects(),
      struct_function: &manticore_struct/1
    )
  end

  def manticore_struct(episode) do
    get_id = & &1.id

    %{
      insert: %{
        index: "episodes",
        id: episode.id,
        doc: %{
          title: episode.title || "",
          subtitle: episode.subtitle || "",
          description: episode.description || "",
          summary: episode.summary || "",
          shownotes: episode.shownotes || "",
          inserted_at: to_unix(episode.inserted_at),
          podcast_id: episode.podcast.id,
          language_ids:
            (episode.podcast.languages && Enum.map(episode.podcast.languages, get_id)) || [],
          category_ids:
            (episode.podcast.categories && Enum.map(episode.podcast.categories, get_id)) || [],
          gig_ids: (episode.gigs && Enum.map(episode.gigs, get_id)) || [],
          gigs:
            Enum.map(
              episode.gigs,
              &%{persona_name: &1.persona.name, persona_id: &1.persona_id, role: &1.role}
            )
            |> Jason.encode!(),
          languages:
            Enum.map(
              episode.podcast.languages,
              &%{id: &1.id, shortcode: &1.shortcode, name: &1.name, emoji: &1.emoji}
            )
            |> Jason.encode!(),
          categories:
            Enum.map(episode.podcast.categories, &%{id: &1.id, title: &1.title})
            |> Jason.encode!(),
          podcast: %{id: episode.podcast.id, title: episode.podcast.title} |> Jason.encode!()
        }
      }
    }
  end

  defp to_unix(naive) do
    {:ok, date_time} = DateTime.from_naive(naive, "Etc/UTC")
    DateTime.to_unix(date_time)
  end

  def batch_reset do
    Logger.info("=== full_text reset up to 10_000 episodes ===")

    episode_ids =
      from(e in Episode,
        where: e.full_text == true,
        select: e.id,
        limit: 10_000
      )
      |> Repo.all(timeout: 999_999)

    from(e in Episode, where: e.id in ^episode_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(episode_ids) > 0, do: batch_reset()
  end

  def update_index(id) do
    episode =
      from(e in Episode, where: e.id == ^id, preload: ^preloads(), select: ^selects())
      |> Repo.one()

    if episode.podcast.blocked do
      delete_index(id)
    else
      manticore_struct(episode)[:insert]
      |> Jason.encode!()
      |> Manticore.post("replace")
    end
  end

  def delete_index(id) do
    %{index: "episodes", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete")
  end

  def delete_index_orphans() do
    episode_ids =
      from(e in Episode, select: e.id)
      |> Repo.all()

    max_episode_id = Enum.max(episode_ids)

    all_ids =
      Range.new(1, max_episode_id)
      |> Enum.to_list()

    for id <- all_ids do
      unless Enum.member?(episode_ids, id) do
        delete_index(id)
      end
    end
  end
end
