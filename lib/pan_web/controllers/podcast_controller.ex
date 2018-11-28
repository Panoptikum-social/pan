defmodule PanWeb.PodcastController do
  use Pan.Web, :controller
  alias PanWeb.{AlternateFeed, Chapter, Category, Enclosure, Episode, Feed, Gig, Like,
                Podcast, Recommendation}
  require Logger

  plug :scrub_params, "podcast" when action in [:create, :update]

  def orphans(conn, _params) do
    unassigned_podcasts =
      from(p in Podcast, left_join: c in assoc(p, :categories),
                         where: is_nil(c.id) and is_false(p.blocked))
      |> Repo.all

    podcasts_without_episodes = from(p in Podcast, where: p.episodes_count == 0)
                                |> Repo.all()

    render(conn, "orphans.html", unassigned_podcasts: unassigned_podcasts,
                                 podcasts_without_episodes: podcasts_without_episodes)
  end

  def assign_to_unsorted(conn, _params) do
    podcast_ids = from(a in "categories_podcasts", group_by: a.podcast_id,
                                                   select:   a.podcast_id)
                  |> Repo.all

    podcasts = from(p in Podcast, where: p.id not in ^podcast_ids and is_false(p.blocked))
               |> Repo.all

    category = Repo.get_by(Category, title: "Unsorted")
               |> Repo.preload(:podcasts)

    Ecto.Changeset.change(category)
    |> Ecto.Changeset.put_assoc(:podcasts, category.podcasts ++ podcasts)
    |> Repo.update!


    put_flash(conn, :info, "Podcasts assigned successfully.")
    |> redirect(to: podcast_path(conn, :orphans))
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, params) do
    search = params["search"]["value"]
    searchfrag = "%#{params["search"]["value"]}%"

    limit = String.to_integer(params["length"])
    offset = String.to_integer(params["start"])
    draw = String.to_integer(params["draw"])

    columns = params["columns"]

    order_by = Enum.map(params["order"], fn({_key, value}) ->
                 column_number = value["column"]
                 {String.to_atom(value["dir"]), String.to_atom(columns[column_number]["data"])}
               end)

    records_total = Repo.aggregate(Podcast, :count, :id)

    query =
      if search != "" do
        from(p in Podcast, where: ilike(p.title, ^searchfrag) or
                                  ilike(p.website, ^searchfrag) or
                                  ilike(fragment("cast (? as text)", p.id), ^searchfrag))
      else
        from(p in Podcast)
      end

    records_filtered = query
                       |> Repo.aggregate(:count, :id)

    podcasts = from(p in query, limit: ^limit,
                                offset: ^offset,
                                order_by: ^order_by,
                                select: %{id: p.id,
                                          title: p.title,
                                          update_paused: p.update_paused,
                                          updated_at: p.updated_at,
                                          update_intervall: p.update_intervall,
                                          next_update: p.next_update,
                                          website: p.website,
                                          failure_count: p.failure_count})
           |> Repo.all()

    render(conn, "datatable.json", podcasts: podcasts,
                                   draw: draw,
                                   records_total: records_total,
                                   records_filtered: records_filtered)
  end

  def stale(conn, _params) do
    render(conn, "stale.html")
  end

  def datatable_stale(conn, params) do
    search = params["search"]["value"]
    searchfrag = "%#{params["search"]["value"]}%"

    limit = String.to_integer(params["length"])
    offset = String.to_integer(params["start"])
    draw = String.to_integer(params["draw"])

    columns = params["columns"]

    order_by = Enum.map(params["order"], fn({_key, value}) ->
                 column_number = value["column"]
                 {String.to_atom(value["dir"]), String.to_atom(columns[column_number]["data"])}
               end)

    records_total = Repo.aggregate(Podcast, :count, :id)

    query =
      if search != "" do
        from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                  is_false(p.update_paused) and is_false(p.retired) and
                                  (ilike(p.title, ^searchfrag) or
                                   ilike(p.website, ^searchfrag) or
                                   ilike(fragment("cast (? as text)", p.id), ^searchfrag)))
      else
        from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                  is_false(p.update_paused) and is_false(p.retired))
      end

    records_filtered = query
                       |> Repo.aggregate(:count, :id)

    podcasts = from(p in query, join: f in assoc(p, :feeds),
                                limit: ^limit,
                                offset: ^offset,
                                order_by: ^order_by,
                                select: %{id: p.id,
                                          title: p.title,
                                          update_paused: p.update_paused,
                                          updated_at: p.updated_at,
                                          update_intervall: p.update_intervall,
                                          feed_url: f.self_link_url,
                                          next_update: p.next_update,
                                          website: p.website,
                                          failure_count: p.failure_count})
           |> Repo.all()

    render(conn, "datatable_stale.json", podcasts: podcasts,
                                         draw: draw,
                                         records_total: records_total,
                                         records_filtered: records_filtered)
  end

  def factory(conn, _params) do
    podcasts = from(p in Podcast, order_by: [asc: :updated_at],
                                  where: p.update_paused == true and is_false(p.retired),
                                  preload: :feeds)
               |> Repo.all()

    render(conn, "factory.html", podcasts: podcasts)
  end

  def new(conn, _params) do
    changeset = Podcast.changeset(%Podcast{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"podcast" => podcast_params}) do
    changeset = Podcast.changeset(%Podcast{}, podcast_params)

    case Repo.insert(changeset) do
      {:ok, _podcast} ->
        put_flash(conn, :info, "Podcast created successfully.")
        |> redirect(to: podcast_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
              |> Repo.preload(episodes: from(e in Episode, order_by: [desc: e.publishing_date],
                                                           limit: 100))
              |> Repo.preload(episodes: :podcast)
              |> Repo.preload(feeds: :podcast)
              |> Repo.preload([:languages, :categories, :contributors])

    render(conn, "show.html", podcast: podcast)
  end

  def edit(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    changeset = Podcast.changeset(podcast)
    render(conn, "edit.html", podcast: podcast, changeset: changeset)
  end

  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    id = String.to_integer(id)
    podcast = Repo.get!(Podcast, id)
    changeset = Podcast.changeset(podcast, podcast_params)

    case Repo.update(changeset) do
      {:ok, podcast} ->
        Podcast.update_search_index(id)
        Podcast.remove_unwanted_references(id)

        put_flash(conn, :info, "Podcast updated successfully.")
        |> redirect(to: podcast_path(conn, :show, podcast))
      {:error, changeset} ->
        render(conn, "edit.html", podcast: podcast, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    id = String.to_integer(id)
    podcast = Repo.get!(Podcast, id)
              |> Repo.preload(episodes: :chapters)
              |> Repo.preload(:feeds)

    for episode <- podcast.episodes do
      for chapter <- episode.chapters do
        Repo.delete_all(from l in Like, where: l.chapter_id == ^chapter.id)
        Repo.delete_all(from r in Recommendation, where: r.chapter_id == ^chapter.id)
      end
      Repo.delete_all(from c in Chapter, where: c.episode_id == ^episode.id)
      Repo.delete_all(from e in Enclosure, where: e.episode_id == ^episode.id)
      Repo.delete_all(from g in Gig, where: g.episode_id == ^episode.id)
    end

    for feed <- podcast.feeds do
      Repo.delete_all(from a in AlternateFeed, where: a.feed_id == ^feed.id)
    end

    Repo.delete!(podcast)
    Podcast.delete_search_index(id)

    conn
    |> put_flash(:info, "Podcast deleted successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end

  def delta_import(conn, %{"id" => id}, forced \\ false, no_failure_count_increase \\ false) do
    podcast = Repo.get!(Podcast, id)
    current_user = conn.assigns.current_user

    case Pan.Updater.Podcast.import_new_episodes(podcast, current_user, forced, no_failure_count_increase) do
      {:ok,    message} -> put_flash(conn, :info, message)
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
      {:ok,    message} -> put_flash(conn, :info, message)
      {:error, message} -> put_flash(conn, :error, message)
    end
    |> redirect(to: podcast_path(conn, :show, id))
  end

  def fix_owner(conn, %{"id" => id}) do
    Pan.Parser.Podcast.fix_owner(id)

    conn
    |> put_flash(:info, "Owner fixed successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end

  def fix_languages(conn, _params) do
    podcast_ids = from(a in "languages_podcasts", group_by: a.podcast_id,
                                                  select:   a.podcast_id)
                  |> Repo.all

    podcasts_without_languages = from(p in Podcast, where: is_false(p.update_paused) and
                                                           p.id not in ^podcast_ids)
                                 |> Repo.all()
                                 |> Enum.shuffle()

    for {podcast, index} <- Enum.with_index(podcasts_without_languages) do
      Logger.info ("#{index} of #{length(podcasts_without_languages)}")
      Pan.Parser.Podcast.fix_language(podcast)
    end

    conn
    |> put_flash(:info, "Languages fixed successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end

  def delta_import_all(conn, _params) do
    current_user = conn.assigns.current_user

    podcasts = from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                         is_false(p.update_paused) and is_false(p.retired),
                                  order_by: [asc: :next_update],
                                  limit: 2000)
                  |> Repo.all()

    Task.start(fn -> trigger_import_new_episodes(podcasts, current_user) end)
    
    put_flash(conn, :info, "Async podcasts update Task started .")
    |> redirect(to: podcast_path(conn, :stale))
  end

  defp trigger_import_new_episodes(podcasts, current_user) do
    for podcast <- podcasts do
      Pan.Updater.Podcast.import_new_episodes(podcast, current_user)
    end
    Logger.info "=== Manual triggered podcast update finished ==="
  end

  def touch(conn, %{"id" => id}) do
    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset
    |> Repo.update([force: true])


    put_flash(conn, :info, "Podcast touched.")
    |> redirect(to: podcast_path(conn, :index))
  end

  def pause(conn, %{"id" => id}) do
    from(p in Podcast, where: p.id == ^id)
    |> Repo.update_all(set: [update_paused: true])

    put_flash(conn, :info, "Podcast paused.")
    |> redirect(to: podcast_path(conn, :index))
  end

  def retirement(conn, _params) do
    candidates = from(p in Podcast, where: is_false(p.retired),
                                    join: e in assoc(p, :episodes),
                                    group_by: p.id,
                                    having: max(e.publishing_date) < ago(1, "year"),
                                    select: %{id: p.id,
                                              title: p.title,
                                              last_build_date: p.last_build_date,
                                              last_episode_date: max(e.publishing_date)},
                                    order_by: max(e.publishing_date))
                 |> Repo.all()

    retired = from(p in Podcast, where: p.retired == true)
              |> Repo.all

    render(conn, "retirement.html", candidates: candidates,
                                    retired: retired)
  end

  def retire(conn, %{"id" => id}) do
    from(p in Podcast, where: p.id == ^id)
    |> Repo.update_all(set: [retired: true])

    conn
    |> put_flash(:info, "Podcast retired.")
    |> redirect(to: podcast_path(conn, :retirement))
  end

  def duplicates(conn, _params) do
    duplicate_feeds = from(f in Feed, group_by: f.self_link_url,
                                      having: count(f.id) > 1,
                                      select: f.self_link_url)
                      |> Repo.all()

    feeds = from(f in Feed, where: f.self_link_url in ^duplicate_feeds,
                            order_by: f.self_link_url,
                            preload: :podcast)
            |> Repo.all()

    render(conn, "duplicates.html", feeds: feeds)
  end

  def update_from_feed(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    case Pan.Parser.Podcast.update_from_feed(podcast) do
      {:ok,    message} -> put_flash(conn, :info, message)
      {:error, message} -> put_flash(conn, :error, message)
    end
    |> redirect(to: podcast_path(conn, :show, podcast.id))
  end

  def update_missing_counters(conn, _params) do
    podcasts = from(p in Podcast, where: p.publication_frequency == 0.0)
               |> Repo.all()

    Task.start(fn -> update_missing_counters_async(podcasts) end)
    render(conn, "done.html")
  end

  defp update_missing_counters_async(podcasts) do
    for podcast <- podcasts do
      Podcast.changeset(podcast)
      |> Podcast.update_counters()
      |> Repo.update()
    end
  end
end