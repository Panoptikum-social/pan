defmodule PanWeb.FeedController do
  use Pan.Web, :controller
  alias PanWeb.{AlternateFeed, Feed}

  plug :scrub_params, "feed" when action in [:create, :update]


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

    records_total = Repo.aggregate(Feed, :count, :id)

    query =
      if search != "" do
        from(f in Feed, join: podcast in assoc(f, :podcast),
                        where: ilike(f.self_link_title, ^searchfrag) or
                               ilike(f.self_link_url, ^searchfrag) or
                               ilike(podcast.title, ^searchfrag) or
                               ilike(fragment("cast (? as text)", f.podcast_id), ^searchfrag) or
                               ilike(fragment("cast (? as text)", f.id), ^searchfrag))
      else
        from(f in Feed)
      end

    records_filtered = query
                       |> Repo.aggregate(:count, :id)

    feeds = from(f in query, limit: ^limit,
                             offset: ^offset,
                             order_by: ^order_by,
                             join: podcast in assoc(f, :podcast),
                             select: %{id: f.id,
                                       self_link_title: f.self_link_title,
                                       self_link_url: f.self_link_url,
                                       feed_generator: f.feed_generator,
                                       podcast_id: f.podcast_id,
                                       podcast_title: podcast.title})
            |> Repo.all()

    render(conn, "datatable.json", feeds: feeds,
                                   draw: draw,
                                   records_total: records_total,
                                   records_filtered: records_filtered)

  end


  def new(conn, _params) do
    changeset = Feed.changeset(%Feed{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"feed" => feed_params}) do
    changeset = Feed.changeset(%Feed{}, feed_params)

    case Repo.insert(changeset) do
      {:ok, _feed} ->
        conn
        |> put_flash(:info, "Feed created successfully.")
        |> redirect(to: feed_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    feed = Repo.get!(Feed, id)
           |> Repo.preload(:alternate_feeds)
    render(conn, "show.html", feed: feed)
  end


  def edit(conn, %{"id" => id}) do
    feed = Repo.get!(Feed, id)
           |> Repo.preload(:alternate_feeds)
    changeset = Feed.changeset(feed)
                |> Ecto.Changeset.put_assoc(:alternate_feeds, [%AlternateFeed{} | feed.alternate_feeds])
    render(conn, "edit.html", feed: feed, changeset: changeset)
  end


  def update(conn, %{"id" => id, "feed" => feed_params}) do
    feed = Repo.get!(Feed, id)
           |> Repo.preload(:alternate_feeds)

    feed_params =
      if feed_params["alternate_feeds"]["0"]["title"] == nil and feed_params["alternate_feeds"]["0"]["url"] == nil do
        {_, feed_params} = Kernel.pop_in(feed_params["alternate_feeds"]["0"])
        feed_params
      else
        feed_params
      end

    changeset = Feed.changeset(feed, feed_params)

    case Repo.update(changeset) do
      {:ok, feed} ->
        conn
        |> put_flash(:info, "Feed updated successfully.")
        |> redirect(to: feed_path(conn, :show, feed))
      {:error, changeset} ->
        render(conn, "edit.html", feed: feed, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    feed = Repo.get!(Feed, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(feed)

    conn
    |> put_flash(:info, "Feed deleted successfully.")
    |> redirect(to: feed_path(conn, :index))
  end


  def make_only(conn, %{"id" => id}) do
    primary_feed = Repo.get!(Feed, id)

    other_feeds = Repo.all(from f in Feed, where: f.podcast_id == ^primary_feed.podcast_id and
                                                  f.id != ^primary_feed.id)
    for feed <- other_feeds do
      # move alternate feeds over to primary feed
      from(a in AlternateFeed, where: a.feed_id == ^feed.id)
      |> Repo.update_all(set: [feed_id: primary_feed.id])

      # create replacement
      %AlternateFeed{feed_id: primary_feed.id,
                     title: feed.self_link_url,
                     url: feed.self_link_url}
      |> Repo.insert()

      Repo.delete!(feed)
    end

    conn
    |> put_flash(:info, "Feed made primary successfully.")
    |> redirect(to: podcast_path(conn, :show, primary_feed.podcast_id))
  end
end
