defmodule Pan.Search.Persona do
  alias PanWeb.Persona
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias Pan.Search.Manticore
  require Logger

  def migrate() do
    Manticore.sql("DROP TABLE personas")

    Manticore.sql(
      "CREATE TABLE personas(name text, pid string, uri string, " <>
        "description text, long_description text, thumbnail_url string, " <>
        "image_title text, podcast_ids multi, episode_ids multi, engagements json) " <>
        "min_infix_len='2' html_strip='1' html_remove_elements = 'style, script'"
    )
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
      # needed by manticore_struct/1 and update_index/1 to leave out
      # redirected personas
      :redirect_id,
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

  # redirected personas must not be searchable (their target is) — a bulk
  # delete line keeps them out (and removes them) when batch_index/0 comes
  # across them
  def manticore_struct(%{redirect_id: redirect_id} = persona) when not is_nil(redirect_id) do
    %{delete: %{index: "personas", id: persona.id}}
  end

  # replace, not insert: an insert of an already indexed id fails with
  # "duplicate id", so resetting full_text could never refresh a stale doc
  def manticore_struct(persona) do
    %{
      replace: %{
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
    if image.thumbnails != [] do
      hd(image.thumbnails).path <> hd(image.thumbnails).filename
    else
      ""
    end
  end

  def batch_reset do
    Logger.info("full_text reset up to 10_000 personas")

    persona_ids =
      from(p in Persona,
        where: is_nil(p.full_text) or p.full_text == true,
        select: p.id,
        limit: 10_000
      )
      |> Repo.all()

    from(p in Persona, where: p.id in ^persona_ids)
    |> Repo.update_all(set: [full_text: false])

    if persona_ids != [], do: batch_reset()
  end

  @doc """
  The personas tied to a podcast, via its engagements or gigs on its
  episodes — the ones whose docs (podcast_ids, episode_ids, engagements
  with podcast titles) go stale when the podcast's feed is updated.
  """
  def ids_for_podcast(podcast_id) do
    engaged =
      from(e in PanWeb.Engagement, where: e.podcast_id == ^podcast_id, select: e.persona_id)

    from(g in PanWeb.Gig,
      join: e in assoc(g, :episode),
      where: e.podcast_id == ^podcast_id,
      select: g.persona_id,
      union: ^engaged
    )
    |> Repo.all()
  end

  @doc """
  Episode and podcast docs carry copies of persona names (their gigs and
  engagements, rendered as links in search results). Returns the ids of
  those listing `persona_id` — to be collected before a persona's gigs and
  engagements move (merge) or vanish (delete), and re-flagged afterwards
  with `reset_copies/1`.
  """
  def copy_ids(persona_id) do
    episode_ids =
      from(g in PanWeb.Gig, where: g.persona_id == ^persona_id, select: g.episode_id)
      |> Repo.all()

    podcast_ids =
      from(e in PanWeb.Engagement, where: e.persona_id == ^persona_id, select: e.podcast_id)
      |> Repo.all()

    {episode_ids, podcast_ids}
  end

  # in a background task, as a busy host has gigs on thousands of episodes
  def reset_copies({episode_ids, podcast_ids}) do
    Task.start(fn ->
      from(e in PanWeb.Episode, where: e.id in ^episode_ids)
      |> Repo.update_all([set: [full_text: false]], timeout: :infinity)

      from(p in PanWeb.Podcast, where: p.id in ^podcast_ids)
      |> Repo.update_all([set: [full_text: false]], timeout: :infinity)
    end)
  end

  @doc """
  `update_index/1` after a persona update with the given changeset
  `changes`; a rename also re-flags the episode/podcast docs carrying the
  persona's name.
  """
  def update_index(id, changes) do
    update_index(id)
    if Map.has_key?(changes, :name), do: reset_copies(copy_ids(id))
  end

  def reset(persona_ids) do
    from(p in Persona, where: p.id in ^persona_ids)
    |> Repo.update_all(set: [full_text: false])
  end

  def update_index(id) do
    persona =
      from(p in Persona, where: p.id == ^id, preload: ^preloads(), select: ^selects())
      |> Repo.one()

    if persona.redirect_id do
      delete_index(id)
    else
      manticore_struct(persona)[:replace]
      |> Jason.encode!()
      |> Manticore.post("replace", "application/json")
    end
  end

  def delete_index(id) do
    %{index: "personas", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete", "application/json")
  end

  def delete_index_orphans() do
    Pan.Search.delete_orphans("personas", Persona)
  end
end
