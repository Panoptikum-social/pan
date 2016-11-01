defmodule Pan.FeedBacklogController do
  use Pan.Web, :controller

  alias Pan.FeedBacklog

  def index(conn, _params) do
    backlog_feeds = Repo.all(from f in FeedBacklog, order_by: :url)
    feedcount = Repo.aggregate(FeedBacklog, :count, :id)

    render(conn, "index.html", backlog_feeds: backlog_feeds, feedcount: feedcount)
  end

  def new(conn, _params) do
    changeset = FeedBacklog.changeset(%FeedBacklog{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"feed_backlog" => feed_backlog_params}) do
    changeset = FeedBacklog.changeset(%FeedBacklog{}, feed_backlog_params)

    case Repo.insert(changeset) do
      {:ok, _feed_backlog} ->
        conn
        |> put_flash(:info, "Feed backlog created successfully.")
        |> redirect(to: feed_backlog_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    render(conn, "show.html", feed_backlog: feed_backlog)
  end

  def edit(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    changeset = FeedBacklog.changeset(feed_backlog)
    render(conn, "edit.html", feed_backlog: feed_backlog, changeset: changeset)
  end

  def update(conn, %{"id" => id, "feed_backlog" => feed_backlog_params}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    changeset = FeedBacklog.changeset(feed_backlog, feed_backlog_params)

    case Repo.update(changeset) do
      {:ok, feed_backlog} ->
        conn
        |> put_flash(:info, "Feed backlog updated successfully.")
        |> redirect(to: feed_backlog_path(conn, :show, feed_backlog))
      {:error, changeset} ->
        render(conn, "edit.html", feed_backlog: feed_backlog, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(feed_backlog)

    conn
    |> put_flash(:info, "Feed backlog deleted successfully.")
    |> redirect(to: feed_backlog_path(conn, :index))
  end

  def import(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    Pan.Parser.RssFeed.download_and_parse(feed_backlog.url)

    conn
    |> put_flash(:info, "Feed imported successfully.")
    |> redirect(to: feed_backlog_path(conn, :index))
  end
end
