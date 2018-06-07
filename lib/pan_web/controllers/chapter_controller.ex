defmodule PanWeb.ChapterController do
  use Pan.Web, :controller
  alias PanWeb.Chapter

  plug :scrub_params, "chapter" when action in [:create, :update]

  def index(conn, params) do
    chapters = from(Chapter)
               |> Repo.paginate(params)
    render(conn, "index.html", chapters: chapters)
  end

  def new(conn, _params) do
    changeset = Chapter.changeset(%Chapter{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"chapter" => chapter_params}) do
    changeset = Chapter.changeset(%Chapter{}, chapter_params)

    case Repo.insert(changeset) do
      {:ok, _chapter} ->
        conn
        |> put_flash(:info, "Chapter created successfully.")
        |> redirect(to: chapter_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    chapter = Repo.get!(Chapter, id)
    render(conn, "show.html", chapter: chapter)
  end

  def edit(conn, %{"id" => id}) do
    chapter = Repo.get!(Chapter, id)
    changeset = Chapter.changeset(chapter)
    render(conn, "edit.html", chapter: chapter, changeset: changeset)
  end

  def update(conn, %{"id" => id, "chapter" => chapter_params}) do
    chapter = Repo.get!(Chapter, id)
    changeset = Chapter.changeset(chapter, chapter_params)

    case Repo.update(changeset) do
      {:ok, chapter} ->
        conn
        |> put_flash(:info, "Chapter updated successfully.")
        |> redirect(to: chapter_path(conn, :show, chapter))
      {:error, changeset} ->
        render(conn, "edit.html", chapter: chapter, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    chapter = Repo.get!(Chapter, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(chapter)

    conn
    |> put_flash(:info, "Chapter deleted successfully.")
    |> redirect(to: chapter_path(conn, :index))
  end
end
