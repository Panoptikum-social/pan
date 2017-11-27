defmodule PanWeb.RssFeedController do
  use Pan.Web, :controller
  alias PanWeb.RssFeed

  def index(conn, _params) do
    rss_feeds = from(r in RssFeed)
                |> Repo.all

    render(conn, "index.html", rss_feeds: rss_feeds)
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
