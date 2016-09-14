defmodule Pan.AlternateFeedController do
  use Pan.Web, :controller

  alias Pan.AlternateFeed

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

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(alternate_feed)

    conn
    |> put_flash(:info, "Alternate feed deleted successfully.")
    |> redirect(to: alternate_feed_path(conn, :index))
  end
end
