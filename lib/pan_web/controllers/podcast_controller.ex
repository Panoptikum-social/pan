defmodule PanWeb.PodcastController do
  use PanWeb, :controller

  alias PanWeb.{
    AlternateFeed,
    Category,
    Chapter,
    Enclosure,
    Feed,
    Gig,
    Image,
    Like,
    Podcast,
    Recommendation,
    PageFrontendView
  }

  alias Pan.Search
  require Logger

  plug(:scrub_params, "podcast" when action in [:create, :update])

  def orphans(conn, _params) do
    unassigned_podcasts =
      from(p in Podcast,
        left_join: c in assoc(p, :categories),
        where: is_nil(c.id) and not p.blocked
      )
      |> Repo.all()

    podcasts_without_episodes =
      from(p in Podcast, where: p.episodes_count == 0)
      |> Repo.all()

    render(conn, "orphans.html",
      unassigned_podcasts: unassigned_podcasts,
      podcasts_without_episodes: podcasts_without_episodes
    )
  end

  def assign_to_unsorted(conn, _params) do
    podcast_ids =
      from(a in "categories_podcasts",
        group_by: a.podcast_id,
        select: a.podcast_id
      )
      |> Repo.all()

    podcasts =
      from(p in Podcast, where: p.id not in ^podcast_ids and not p.blocked)
      |> Repo.all()

    category =
      Repo.get_by(Category, title: "Unsorted")
      |> Repo.preload(:podcasts)

    Ecto.Changeset.change(category)
    |> Ecto.Changeset.put_assoc(:podcasts, category.podcasts ++ podcasts)
    |> Repo.update!()

    put_flash(conn, :info, "Podcasts assigned successfully.")
    |> redirect(to: podcast_path(conn, :orphans))
  end

  def factory(conn, _params) do
    podcasts =
      from(p in Podcast,
        order_by: [asc: :updated_at],
        where: p.update_paused == true and not p.retired,
        preload: :feeds
      )
      |> Repo.all()

    render(conn, "factory.html", podcasts: podcasts)
  end

  def delete(conn, %{"id" => id}) do
    # FIXME: Recursive deletion of several Resources, not only podcasts
    id = String.to_integer(id)

    podcast =
      Repo.get!(Podcast, id)
      |> Repo.preload(episodes: :chapters)
      |> Repo.preload(:feeds)

    for episode <- podcast.episodes do
      for chapter <- episode.chapters do
        Repo.delete_all(from(l in Like, where: l.chapter_id == ^chapter.id))
        Repo.delete_all(from(r in Recommendation, where: r.chapter_id == ^chapter.id))
      end

      Repo.delete_all(from(c in Chapter, where: c.episode_id == ^episode.id))
      Repo.delete_all(from(e in Enclosure, where: e.episode_id == ^episode.id))
      Repo.delete_all(from(g in Gig, where: g.episode_id == ^episode.id))

      images = Repo.all(from(i in Image, where: i.episode_id == ^episode.id))

      for image <- images do
        File.rm(image.path)
        Repo.delete!(image)
      end
    end

    for feed <- podcast.feeds do
      Repo.delete_all(from(a in AlternateFeed, where: a.feed_id == ^feed.id))
    end

    Repo.delete!(podcast)
    Search.Podcast.delete_index(id)

    conn
    |> put_flash(:info, "Podcast deleted successfully.")
    |> redirect(to: podcast_frontend_path(conn, :index))
  end

  def delta_import(conn, %{"id" => id}, forced \\ false, no_failure_count_increase \\ false) do
    podcast = Repo.get!(Podcast, id)

    case Pan.Updater.Podcast.import_new_episodes(
           podcast,
           forced,
           no_failure_count_increase
         ) do
      {:ok, message} -> put_flash(conn, :info, message)
      {:error, message} -> put_flash(conn, :error, message)
    end
    |> redirect(to: podcast_path(conn, :show, id))
  end

  def forced_delta_import(conn, %{"id" => id}) do
    delta_import(conn, %{"id" => id}, :forced, false)
    # delta_import(conn, %{"id" => id}, :forced, :no_failure_count_increase)
  end

  def contributor_import(conn, %{"id" => id}) do
    case Pan.Parser.Podcast.contributor_import(id) do
      {:ok, message} -> put_flash(conn, :info, message)
      {:error, message} -> put_flash(conn, :error, message)
    end
    |> redirect(to: podcast_path(conn, :show, id))
  end

  def fix_owner(conn, %{"id" => id}) do
    Pan.Parser.Podcast.fix_owner(id)

    conn
    |> put_flash(:info, "Owner fixed successfully.")
    |> redirect(to: databrowser_path(conn, :index, "podcast"))
  end

  def fix_languages(conn, _params) do
    podcast_ids =
      from(a in "languages_podcasts",
        group_by: a.podcast_id,
        select: a.podcast_id
      )
      |> Repo.all()

    podcasts_without_languages =
      from(p in Podcast,
        where:
          not p.update_paused and
            p.id not in ^podcast_ids
      )
      |> Repo.all()
      |> Enum.shuffle()

    for {podcast, index} <- Enum.with_index(podcasts_without_languages) do
      Logger.info("#{index} of #{length(podcasts_without_languages)}")
      Pan.Parser.Podcast.fix_language(podcast)
    end

    conn
    |> put_flash(:info, "Languages fixed successfully.")
    |> redirect(to: databrowser_path(conn, :index, "podcast"))
  end

  def touch(conn, %{"id" => id}) do
    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> Repo.update(force: true)

    put_flash(conn, :info, "Podcast touched.")
    |> redirect(to: databrowser_path(conn, :index, "podcast"))
  end

  def pause(conn, %{"id" => id}) do
    from(p in Podcast, where: p.id == ^id)
    |> Repo.update_all(set: [update_paused: true])

    put_flash(conn, :info, "Podcast paused.")
    |> redirect(to: databrowser_path(conn, :show, "podcast", id))
  end

  def duplicates(conn, _params) do
    duplicate_feeds =
      from(f in Feed,
        group_by: f.self_link_url,
        having: count(f.id) > 1,
        select: f.self_link_url
      )
      |> Repo.all()

    feeds =
      from(f in Feed,
        where: f.self_link_url in ^duplicate_feeds,
        order_by: f.self_link_url,
        preload: :podcast
      )
      |> Repo.all()

    render(conn, "duplicates.html", feeds: feeds)
  end

  def update_from_feed(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)

    case Pan.Parser.Podcast.update_from_feed(podcast) do
      {:ok, message} ->
        Search.Podcast.update_index(id)
        Podcast.remove_unwanted_references(id)
        put_flash(conn, :info, message)

      {:error, message} ->
        put_flash(conn, :error, message)
    end
    |> redirect(to: podcast_path(conn, :show, podcast.id))
  end

  def update_missing_counters(conn, _params) do
    podcasts =
      from(p in Podcast,
        where:
          p.publication_frequency == 0.0 and
            p.episodes_count > 1,
        limit: 1000
      )
      |> Repo.all()

    Task.start(fn -> update_missing_counters_async(podcasts) end)
    render(conn, PageFrontendView, "done.html")
  end

  defp update_missing_counters_async(podcasts) do
    for {podcast, index} <- Enum.with_index(podcasts) do
      Podcast.changeset(podcast)
      |> Podcast.update_counters()
      |> Repo.update()

      Logger.info("Fixed counter for Podcast #{index} / id #{podcast.id}")
    end

    Logger.info("Counter update job finished")
  end
end
