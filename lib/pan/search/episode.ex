defmodule Pan.Search.Episode do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.Episode
  alias Pan.Search.Manticore
  require Logger

  def migrate() do
    Manticore.sql("DROP TABLE episodes")

    Manticore.sql(
      "CREATE TABLE episodes(title text, subtitle text, description text, " <>
        "summary text, shownotes text, inserted_at timestamp, " <>
        "podcast_id int, language_ids multi, category_ids multi, gig_ids multi," <>
        "podcast json, languages json, categories json, gigs json) " <>
        "min_infix_len='2' html_strip='1' html_remove_elements = 'style, script'"
    )
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

  # episodes of blocked podcasts must not be searchable — a bulk delete line
  # keeps them out (and removes them) when batch_index/0 comes across them
  def manticore_struct(%{podcast: %{blocked: true}} = episode) do
    %{delete: %{index: "episodes", id: episode.id}}
  end

  # replace, not insert: an insert of an already indexed id fails with
  # "duplicate id", so resetting full_text could never refresh a stale doc
  def manticore_struct(episode) do
    %{
      replace: %{
        index: "episodes",
        id: episode.id,
        doc: %{
          title: nilstr(episode.title),
          subtitle: nilstr(episode.subtitle),
          description: nilstr(episode.description),
          summary: nilstr(episode.summary),
          shownotes: nilstr(episode.shownotes),
          inserted_at: to_unix(episode.inserted_at),
          podcast_id: episode.podcast.id,
          language_ids: ids(episode.podcast.languages),
          category_ids: ids(episode.podcast.categories),
          gig_ids: ids(episode.gigs),
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

  defp nilstr(nil), do: ""
  defp nilstr(val), do: val

  defp ids(nil), do: []
  defp ids(list), do: Enum.map(list, & &1.id)

  defp to_unix(naive) do
    {:ok, date_time} = DateTime.from_naive(naive, "Etc/UTC")
    DateTime.to_unix(date_time)
  end

  def batch_reset do
    Logger.info("full_text reset up to 10_000 episodes")

    episode_ids =
      from(e in Episode,
        where: is_nil(e.full_text) or e.full_text == true,
        select: e.id,
        limit: 10_000
      )
      |> Repo.all(timeout: 999_999)

    from(e in Episode, where: e.id in ^episode_ids)
    |> Repo.update_all(set: [full_text: false])

    if episode_ids != [], do: batch_reset()
  end

  @doc """
  The podcast data every episode doc carries a copy of (see
  `manticore_struct/1`) — when it changes, all of the podcast's episode
  docs are stale.
  """
  def podcast_data(podcast_id) do
    podcast =
      from(p in PanWeb.Podcast, where: p.id == ^podcast_id, preload: [:languages, :categories])
      |> Repo.one()

    {podcast.title, Enum.sort(ids(podcast.languages)), Enum.sort(ids(podcast.categories))}
  end

  @doc """
  The gig data an episode doc shows (persona and role), to tell whether a
  feed update changed it. Gig ids are left out on purpose: the author gig is
  deleted and re-inserted on every update, and the doc's gig_ids aren't
  queried anywhere.
  """
  def gigs_data(episode_id) do
    from(g in PanWeb.Gig,
      where: g.episode_id == ^episode_id,
      select: {g.persona_id, g.role},
      order_by: [g.persona_id, g.role]
    )
    |> Repo.all()
  end

  def reset(episode_ids) do
    from(e in Episode, where: e.id in ^episode_ids)
    |> Repo.update_all(set: [full_text: false])
  end

  def reset_for_podcast(podcast_id) do
    from(e in Episode, where: e.podcast_id == ^podcast_id)
    |> Repo.update_all(set: [full_text: false])
  end

  def update_index(id) do
    episode =
      from(e in Episode, where: e.id == ^id, preload: ^preloads(), select: ^selects())
      |> Repo.one()

    if episode.podcast.blocked do
      delete_index(id)
    else
      manticore_struct(episode)[:replace]
      |> Jason.encode!()
      |> Manticore.post("replace", "application/json")
    end
  end

  def delete_index(id) do
    %{index: "episodes", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete", "application/json")
  end

  def delete_index_orphans() do
    Pan.Search.delete_orphans("episodes", Episode)
  end
end
