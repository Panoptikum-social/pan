defmodule PanWeb.RssFeedController do
  use PanWeb, :controller
  alias PanWeb.RssFeed

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

    order_by =
      Enum.map(params["order"], fn {_key, value} ->
        column_number = value["column"]
        {String.to_atom(value["dir"]), String.to_atom(columns[column_number]["data"])}
      end)

    records_total = Repo.aggregate(RssFeed, :count, :id)

    query =
      if search != "" do
        from(p in RssFeed, where: ilike(fragment("cast (? as text)", p.podcast_id), ^searchfrag))
      else
        from(p in RssFeed)
      end

    records_filtered =
      query
      |> Repo.aggregate(:count)

    rss_feeds =
      from(p in query,
        limit: ^limit,
        offset: ^offset,
        order_by: ^order_by
      )
      |> Repo.all()

    render(conn, "datatable.json",
      rss_feeds: rss_feeds,
      draw: draw,
      records_total: records_total,
      records_filtered: records_filtered
    )
  end

  def new(conn, _params) do
    changeset = RssFeed.changeset(%RssFeed{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"rss_feed" => rss_feed_params}) do
    changeset = RssFeed.changeset(%RssFeed{}, rss_feed_params)

    case Repo.insert(changeset) do
      {:ok, _rss_feed} ->
        conn
        |> put_flash(:info, "Rss feed created successfully.")
        |> redirect(to: rss_feed_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    rss_feed = Repo.get!(RssFeed, id)

    render(conn, "show.html", rss_feed: rss_feed)
  end

  def edit(conn, %{"id" => id}) do
    rss_feed = Repo.get!(RssFeed, id)
    changeset = RssFeed.changeset(rss_feed)
    render(conn, "edit.html", rss_feed: rss_feed, changeset: changeset)
  end

  def update(conn, %{"id" => id, "rss_feed" => rss_feed_params}) do
    rss_feed = Repo.get!(RssFeed, id)
    changeset = RssFeed.changeset(rss_feed, rss_feed_params)

    case Repo.update(changeset) do
      {:ok, rss_feed} ->
        conn
        |> put_flash(:info, "RssFeed updated successfully.")
        |> redirect(to: rss_feed_path(conn, :show, rss_feed))

      {:error, changeset} ->
        render(conn, "edit.html", rss_feed: rss_feed, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    rss_feed = Repo.get!(RssFeed, id)

    Repo.delete!(rss_feed)

    conn
    |> put_flash(:info, "Rss Feed deleted successfully.")
    |> redirect(to: rss_feed_path(conn, :index))
  end
end
