defmodule Pan.FeedController do
  use Pan.Web, :controller

  alias Pan.Feed
  alias Pan.AlternateFeed

  plug :scrub_params, "feed" when action in [:create, :update]


  def index(conn, _params) do
    feeds = Repo.all(Feed)
    feeds = Repo.preload(feeds,:podcast)
    render(conn, "index.html", feeds: feeds)
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
end
