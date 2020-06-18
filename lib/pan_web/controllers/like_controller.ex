defmodule PanWeb.LikeController do
  use Pan.Web, :controller
  alias PanWeb.Like

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, _params) do
    likes =
      from(Like, preload: [:enjoyer, :podcast, :episode, :chapter, :user, :category])
      |> Repo.all()

    render(conn, "datatable.json", likes: likes)
  end

  def new(conn, _params) do
    changeset = Like.changeset(%Like{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"like" => like_params}) do
    changeset = Like.changeset(%Like{}, like_params)

    case Repo.insert(changeset) do
      {:ok, _like} ->
        conn
        |> put_flash(:info, "Like created successfully.")
        |> redirect(to: like_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    like = Repo.get!(Like, id)
    render(conn, "show.html", like: like)
  end

  def edit(conn, %{"id" => id}) do
    like = Repo.get!(Like, id)
    changeset = Like.changeset(like)
    render(conn, "edit.html", like: like, changeset: changeset)
  end

  def update(conn, %{"id" => id, "like" => like_params}) do
    like = Repo.get!(Like, id)
    changeset = Like.changeset(like, like_params)

    case Repo.update(changeset) do
      {:ok, like} ->
        conn
        |> put_flash(:info, "Like updated successfully.")
        |> redirect(to: like_path(conn, :show, like))

      {:error, changeset} ->
        render(conn, "edit.html", like: like, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    like = Repo.get!(Like, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(like)

    conn
    |> put_flash(:info, "Like deleted successfully.")
    |> redirect(to: like_path(conn, :index))
  end
end
