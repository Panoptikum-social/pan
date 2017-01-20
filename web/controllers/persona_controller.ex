defmodule Pan.PersonaController do
  use Pan.Web, :controller
  alias Pan.Persona

  def index(conn, _params) do
    personas = Repo.all(Persona)
    render(conn, "index.html", personas: personas)
  end


  def new(conn, _params) do
    changeset = Persona.changeset(%Persona{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"persona" => persona_params}) do
    changeset = Persona.changeset(%Persona{}, persona_params)

    case Repo.insert(changeset) do
      {:ok, _persona} ->
        conn
        |> put_flash(:info, "Persona created successfully.")
        |> redirect(to: persona_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)
    render(conn, "show.html", persona: persona)
  end


  def edit(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)
    changeset = Persona.changeset(persona)
    render(conn, "edit.html", persona: persona, changeset: changeset)
  end


  def update(conn, %{"id" => id, "persona" => persona_params}) do
    persona = Repo.get!(Persona, id)
    changeset = Persona.changeset(persona, persona_params)

    case Repo.update(changeset) do
      {:ok, persona} ->
        conn
        |> put_flash(:info, "Persona updated successfully.")
        |> redirect(to: persona_path(conn, :show, persona))
      {:error, changeset} ->
        render(conn, "edit.html", persona: persona, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(persona)

    conn
    |> put_flash(:info, "Persona deleted successfully.")
    |> redirect(to: persona_path(conn, :index))
  end
end