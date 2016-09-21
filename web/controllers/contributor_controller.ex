defmodule Pan.ContributorController do
  use Pan.Web, :controller

  alias Pan.Contributor

  plug :scrub_params, "contributor" when action in [:create, :update]

  def index(conn, _params) do
    contributors = Repo.all(Contributor)
    render(conn, "index.html", contributors: contributors)
  end

  def new(conn, _params) do
    changeset = Contributor.changeset(%Contributor{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"contributor" => contributor_params}) do
    changeset = Contributor.changeset(%Contributor{}, contributor_params)

    case Repo.insert(changeset) do
      {:ok, _contributor} ->
        conn
        |> put_flash(:info, "Contributor created successfully.")
        |> redirect(to: contributor_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    contributor = Repo.get!(Contributor, id)
    render(conn, "show.html", contributor: contributor)
  end

  def edit(conn, %{"id" => id}) do
    contributor = Repo.get!(Contributor, id)
    changeset = Contributor.changeset(contributor)
    render(conn, "edit.html", contributor: contributor, changeset: changeset)
  end

  def update(conn, %{"id" => id, "contributor" => contributor_params}) do
    contributor = Repo.get!(Contributor, id)
    changeset = Contributor.changeset(contributor, contributor_params)

    case Repo.update(changeset) do
      {:ok, contributor} ->
        conn
        |> put_flash(:info, "Contributor updated successfully.")
        |> redirect(to: contributor_path(conn, :show, contributor))
      {:error, changeset} ->
        render(conn, "edit.html", contributor: contributor, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    contributor = Repo.get!(Contributor, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(contributor)

    conn
    |> put_flash(:info, "Contributor deleted successfully.")
    |> redirect(to: contributor_path(conn, :index))
  end
end
