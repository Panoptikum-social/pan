defmodule Pan.GigController do
  use Pan.Web, :controller

  alias Pan.Gig

  def index(conn, _params) do
    gigs = Repo.all(Gig)
    render(conn, "index.html", gigs: gigs)
  end

  def new(conn, _params) do
    changeset = Gig.changeset(%Gig{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"gig" => gig_params}) do
    changeset = Gig.changeset(%Gig{}, gig_params)

    case Repo.insert(changeset) do
      {:ok, _gig} ->
        conn
        |> put_flash(:info, "Gig created successfully.")
        |> redirect(to: gig_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    gig = Repo.get!(Gig, id)
    render(conn, "show.html", gig: gig)
  end

  def edit(conn, %{"id" => id}) do
    gig = Repo.get!(Gig, id)
    changeset = Gig.changeset(gig)
    render(conn, "edit.html", gig: gig, changeset: changeset)
  end

  def update(conn, %{"id" => id, "gig" => gig_params}) do
    gig = Repo.get!(Gig, id)
    changeset = Gig.changeset(gig, gig_params)

    case Repo.update(changeset) do
      {:ok, gig} ->
        conn
        |> put_flash(:info, "Gig updated successfully.")
        |> redirect(to: gig_path(conn, :show, gig))
      {:error, changeset} ->
        render(conn, "edit.html", gig: gig, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    gig = Repo.get!(Gig, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(gig)

    conn
    |> put_flash(:info, "Gig deleted successfully.")
    |> redirect(to: gig_path(conn, :index))
  end
end
