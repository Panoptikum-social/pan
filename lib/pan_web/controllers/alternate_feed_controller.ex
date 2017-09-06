defmodule PanWeb.AlternateFeedController do
  use Pan.Web, :controller

  alias PanWeb.AlternateFeed

  plug :scrub_params, "alternate_feed" when action in [:create, :update]

  def index(conn, _params) do
    alternate_feeds = Repo.all(AlternateFeed)
    render(conn, "index.html", alternate_feeds: alternate_feeds)
  end


  def new(conn, _params) do
    changeset = AlternateFeed.changeset(%AlternateFeed{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"alternate_feed" => alternate_feed_params}) do
    changeset = AlternateFeed.changeset(%AlternateFeed{}, alternate_feed_params)

    case Repo.insert(changeset) do
      {:ok, _alternate_feed} ->
        conn
        |> put_flash(:info, "Alternate feed created successfully.")
        |> redirect(to: alternate_feed_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def create_from_backlog(conn, %{"feed_id" => feed_id, "url" => url, "backlog_id" => backlog_id}) do
    changeset = AlternateFeed.changeset(%AlternateFeed{title: url,
                                                       url: url,
                                                       feed_id: String.to_integer(feed_id)})

    case Repo.insert(changeset) do
      {:ok, _alternate_feed} ->
        conn
        |> put_flash(:info, "Alternate feed created successfully.")
        |> redirect(to: feed_backlog_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not create alternate feed.")
        |> redirect(to: feed_backlog_path(conn, :show, String.to_integer(backlog_id)))
    end
  end


  def show(conn, %{"id" => id}) do
    alternate_feed = Repo.get!(AlternateFeed, id)
    render(conn, "show.html", alternate_feed: alternate_feed)
  end


  def edit(conn, %{"id" => id}) do
    alternate_feed = Repo.get!(AlternateFeed, id)
    changeset = AlternateFeed.changeset(alternate_feed)
    render(conn, "edit.html", alternate_feed: alternate_feed, changeset: changeset)
  end


  def update(conn, %{"id" => id, "alternate_feed" => alternate_feed_params}) do
    alternate_feed = Repo.get!(AlternateFeed, id)
    changeset = AlternateFeed.changeset(alternate_feed, alternate_feed_params)

    case Repo.update(changeset) do
      {:ok, alternate_feed} ->
        conn
        |> put_flash(:info, "Alternate feed updated successfully.")
        |> redirect(to: alternate_feed_path(conn, :show, alternate_feed))
      {:error, changeset} ->
        render(conn, "edit.html", alternate_feed: alternate_feed, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    alternate_feed = Repo.get!(AlternateFeed, id)
    feed_id = alternate_feed.feed_id

    Repo.delete!(alternate_feed)

    conn
    |> put_flash(:info, "Alternate feed deleted successfully.")
    |> redirect(to: feed_path(conn, :show, feed_id))
  end
end
