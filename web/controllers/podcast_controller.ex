defmodule Pan.PodcastController do
  use Pan.Web, :controller

  alias Pan.Podcast

  plug :scrub_params, "podcast" when action in [:create, :update]

  def index(conn, _params) do
    podcasts = Repo.all(Podcast)
    render(conn, "index.html", podcasts: podcasts)
  end

  def new(conn, _params) do
    changeset = Podcast.changeset(%Podcast{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"podcast" => podcast_params}) do
    changeset = Podcast.changeset(%Podcast{}, podcast_params)

    case Repo.insert(changeset) do
      {:ok, _podcast} ->
        conn
        |> put_flash(:info, "Podcast created successfully.")
        |> redirect(to: podcast_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
              |> Repo.preload(episodes: :podcast)
              |> Repo.preload(feeds: :podcast)
              |> Repo.preload([:language, :owner, :categories])
    render(conn, "show.html", podcast: podcast)
  end

  def edit(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    changeset = Podcast.changeset(podcast)
    render(conn, "edit.html", podcast: podcast, changeset: changeset)
  end

  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    podcast = Repo.get!(Podcast, id)
    changeset = Podcast.changeset(podcast, podcast_params)

    case Repo.update(changeset) do
      {:ok, podcast} ->
        conn
        |> put_flash(:info, "Podcast updated successfully.")
        |> redirect(to: podcast_path(conn, :show, podcast))
      {:error, changeset} ->
        render(conn, "edit.html", podcast: podcast, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(podcast)

    conn
    |> put_flash(:info, "Podcast deleted successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end
end
