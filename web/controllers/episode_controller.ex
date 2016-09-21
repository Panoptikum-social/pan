defmodule Pan.EpisodeController do
  use Pan.Web, :controller

  alias Pan.Episode

  plug :scrub_params, "episode" when action in [:create, :update]

  def index(conn, _params) do
    episodes = Repo.all(Episode)
    unless episodes == nil do
      episodes = Repo.preload(episodes,:podcast)
    end
    render(conn, "index.html", episodes: episodes)
  end

  def new(conn, _params) do
    changeset = Episode.changeset(%Episode{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"episode" => episode_params}) do
    changeset = Episode.changeset(%Episode{}, episode_params)

    case Repo.insert(changeset) do
      {:ok, _episode} ->
        conn
        |> put_flash(:info, "Episode created successfully.")
        |> redirect(to: episode_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
    episode = Repo.preload(episode,:podcast)
    render(conn, "show.html", episode: episode)
  end

  def edit(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
    changeset = Episode.changeset(episode)
    render(conn, "edit.html", episode: episode, changeset: changeset)
  end

  def update(conn, %{"id" => id, "episode" => episode_params}) do
    episode = Repo.get!(Episode, id)
    changeset = Episode.changeset(episode, episode_params)

    case Repo.update(changeset) do
      {:ok, episode} ->
        conn
        |> put_flash(:info, "Episode updated successfully.")
        |> redirect(to: episode_path(conn, :show, episode))
      {:error, changeset} ->
        render(conn, "edit.html", episode: episode, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(episode)

    conn
    |> put_flash(:info, "Episode deleted successfully.")
    |> redirect(to: episode_path(conn, :index))
  end
end
