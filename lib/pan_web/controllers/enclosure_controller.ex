defmodule PanWeb.EnclosureController do
  use Pan.Web, :controller
  alias PanWeb.Enclosure

  plug :scrub_params, "enclosure" when action in [:create, :update]

  def index(conn, params) do
    enclosures = from(Enclosure)
               |> Repo.paginate(params)
    render(conn, "index.html", enclosures: enclosures)
  end

  def new(conn, _params) do
    changeset = Enclosure.changeset(%Enclosure{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"enclosure" => enclosure_params}) do
    changeset = Enclosure.changeset(%Enclosure{}, enclosure_params)

    case Repo.insert(changeset) do
      {:ok, _enclosure} ->
        conn
        |> put_flash(:info, "Enclosure created successfully.")
        |> redirect(to: enclosure_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    enclosure = Repo.get!(Enclosure, id)
    render(conn, "show.html", enclosure: enclosure)
  end

  def edit(conn, %{"id" => id}) do
    enclosure = Repo.get!(Enclosure, id)
    changeset = Enclosure.changeset(enclosure)
    render(conn, "edit.html", enclosure: enclosure, changeset: changeset)
  end

  def update(conn, %{"id" => id, "enclosure" => enclosure_params}) do
    enclosure = Repo.get!(Enclosure, id)
    changeset = Enclosure.changeset(enclosure, enclosure_params)

    case Repo.update(changeset) do
      {:ok, enclosure} ->
        conn
        |> put_flash(:info, "Enclosure updated successfully.")
        |> redirect(to: enclosure_path(conn, :show, enclosure))
      {:error, changeset} ->
        render(conn, "edit.html", enclosure: enclosure, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    enclosure = Repo.get!(Enclosure, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(enclosure)

    conn
    |> put_flash(:info, "Enclosure deleted successfully.")
    |> redirect(to: enclosure_path(conn, :index))
  end
end
