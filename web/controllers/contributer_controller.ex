defmodule Pan.ContributerController do
  use Pan.Web, :controller

  alias Pan.Contributer

  plug :scrub_params, "contributer" when action in [:create, :update]

  def index(conn, _params) do
    contributers = Repo.all(Contributer)
    render(conn, "index.html", contributers: contributers)
  end

  def new(conn, _params) do
    changeset = Contributer.changeset(%Contributer{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"contributer" => contributer_params}) do
    changeset = Contributer.changeset(%Contributer{}, contributer_params)

    case Repo.insert(changeset) do
      {:ok, _contributer} ->
        conn
        |> put_flash(:info, "Contributer created successfully.")
        |> redirect(to: contributer_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    contributer = Repo.get!(Contributer, id)
    render(conn, "show.html", contributer: contributer)
  end

  def edit(conn, %{"id" => id}) do
    contributer = Repo.get!(Contributer, id)
    changeset = Contributer.changeset(contributer)
    render(conn, "edit.html", contributer: contributer, changeset: changeset)
  end

  def update(conn, %{"id" => id, "contributer" => contributer_params}) do
    contributer = Repo.get!(Contributer, id)
    changeset = Contributer.changeset(contributer, contributer_params)

    case Repo.update(changeset) do
      {:ok, contributer} ->
        conn
        |> put_flash(:info, "Contributer updated successfully.")
        |> redirect(to: contributer_path(conn, :show, contributer))
      {:error, changeset} ->
        render(conn, "edit.html", contributer: contributer, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    contributer = Repo.get!(Contributer, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(contributer)

    conn
    |> put_flash(:info, "Contributer deleted successfully.")
    |> redirect(to: contributer_path(conn, :index))
  end
end
