defmodule PanWeb.FollowController do
  use PanWeb, :controller
  alias PanWeb.Follow

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, _params) do
    follows =
      from(Follow, preload: [:follower, :podcast, :user, :category])
      |> Repo.all()

    render(conn, "datatable.json", follows: follows)
  end

  def new(conn, _params) do
    changeset = Follow.changeset(%Follow{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"follow" => follow_params}) do
    changeset = Follow.changeset(%Follow{}, follow_params)

    case Repo.insert(changeset) do
      {:ok, _follow} ->
        conn
        |> put_flash(:info, "Follow created successfully.")
        |> redirect(to: follow_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    follow = Repo.get!(Follow, id)
    render(conn, "show.html", follow: follow)
  end

  def edit(conn, %{"id" => id}) do
    follow = Repo.get!(Follow, id)
    changeset = Follow.changeset(follow)
    render(conn, "edit.html", follow: follow, changeset: changeset)
  end

  def update(conn, %{"id" => id, "follow" => follow_params}) do
    follow = Repo.get!(Follow, id)
    changeset = Follow.changeset(follow, follow_params)

    case Repo.update(changeset) do
      {:ok, follow} ->
        conn
        |> put_flash(:info, "Follow updated successfully.")
        |> redirect(to: follow_path(conn, :show, follow))

      {:error, changeset} ->
        render(conn, "edit.html", follow: follow, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    follow = Repo.get!(Follow, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(follow)

    conn
    |> put_flash(:info, "Follow deleted successfully.")
    |> redirect(to: follow_path(conn, :index))
  end
end
