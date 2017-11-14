defmodule PanWeb.EpisodeController do
  use Pan.Web, :controller

  alias PanWeb.Episode

  plug :scrub_params, "episode" when action in [:create, :update]


  def index(conn, params) do
    episodes = from(e in Episode, preload: [:podcast])
               |> Repo.paginate(params)

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
              |> Repo.preload(podcast: :contributors)
              |> Repo.preload([:enclosures, :chapters, :contributors])
    render(conn, "show.html", episode: episode)
  end


  def edit(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
    changeset = Episode.changeset(episode)
    render(conn, "edit.html", episode: episode, changeset: changeset)
  end


  def update(conn, %{"id" => id, "episode" => episode_params}) do
    id = String.to_integer(id)
    episode = Repo.get!(Episode, id)
    changeset = Episode.changeset(episode, episode_params)

    case Repo.update(changeset) do
      {:ok, episode} ->
        Episode.update_search_index(id)

        conn
        |> put_flash(:info, "Episode updated successfully.")
        |> redirect(to: episode_path(conn, :show, episode))
      {:error, changeset} ->
        render(conn, "edit.html", episode: episode, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    id = String.to_integer(id)
    episode = Repo.get!(Episode, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(episode)
    Episode.update_search_index(id)

    conn
    |> put_flash(:info, "Episode deleted successfully.")
    |> redirect(to: episode_path(conn, :index))
  end


  def remove_duplicates(conn, _params) do
    duplicate_episodes = from(e in Episode, group_by: [e.podcast_id, e.guid],
                                            having: count(e.guid) > 1,
                                            select: [e.podcast_id, e.guid])
                         |> Repo.all()

    for [podcast_id, guid] <- duplicate_episodes do
      episode = from(e in Episode, where: e.podcast_id == ^podcast_id and e.guid == ^guid,
                         limit: 1)
                |> Repo.all()
                |> List.first()

      Repo.delete(episode)
      Episode.update_search_index(episode.id)
    end

    render(conn, "duplicates.html", duplicate_episodes: duplicate_episodes)
  end
end
