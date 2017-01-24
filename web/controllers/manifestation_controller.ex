defmodule Pan.ManifestationController do
  use Pan.Web, :controller
  alias Pan.Manifestation
  alias Pan.User
  alias Pan.Persona


  def index(conn, _params) do
    manifestations = Repo.all(Manifestation)
    render(conn, "index.html", manifestations: manifestations)
  end


  def new(conn, _params) do
    changeset = Manifestation.changeset(%Manifestation{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"manifestation" => manifestation_params}) do
    changeset = Manifestation.changeset(%Manifestation{}, manifestation_params)

    case Repo.insert(changeset) do
      {:ok, _manifestation} ->
        conn
        |> put_flash(:info, "Manifestation created successfully.")
        |> redirect(to: manifestation_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    manifestation = Repo.get!(Manifestation, id)
    render(conn, "show.html", manifestation: manifestation)
  end


  def edit(conn, %{"id" => id}) do
    manifestation = Repo.get!(Manifestation, id)
    changeset = Manifestation.changeset(manifestation)
    render(conn, "edit.html", manifestation: manifestation, changeset: changeset)
  end


  def update(conn, %{"id" => id, "manifestation" => manifestation_params}) do
    manifestation = Repo.get!(Manifestation, id)
    changeset = Manifestation.changeset(manifestation, manifestation_params)

    case Repo.update(changeset) do
      {:ok, manifestation} ->
        conn
        |> put_flash(:info, "Manifestation updated successfully.")
        |> redirect(to: manifestation_path(conn, :show, manifestation))
      {:error, changeset} ->
        render(conn, "edit.html", manifestation: manifestation, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    manifestation = Repo.get!(Manifestation, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(manifestation)

    conn
    |> put_flash(:info, "Manifestation deleted successfully.")
    |> redirect(to: manifestation_path(conn, :index))
  end


  def manifest(conn, _params) do
    users = Repo.all(User)
    personas = Repo.all(Persona)
    render(conn, "manifest.html", users: users,
                                  personas: personas)
  end


  def get(conn, %{"id" => id}) do
    manifestations = from(m in Manifestation, where: m.user_id == ^id,
                                              preload: :persona)
                     |> Repo.all()

    conn
    |> put_layout(false)
    |> render("get.html", manifestations: manifestations)
  end
end
