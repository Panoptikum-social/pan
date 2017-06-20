defmodule Pan.PersonaController do
  use Pan.Web, :controller
  alias Pan.Persona

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, _params) do
    personas = Repo.all(Persona)
    render conn, "datatable.json", personas: personas
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


  def merge_candidates(conn, _params) do
    non_unique_names = from(p in Persona, group_by: p.name,
                                          having: count(p.id) > 1,
                                          select: {p.name, count(p.id)},
                                          limit: 100)
                 |> Repo.all()

    render(conn, "merge_candidates.html", non_unique_names: non_unique_names)
  end


  def merge_candidate_group(conn, %{"name" => name}) do
    personas = from(p in Persona, where: p.name == ^name,
                                  preload: [:engagements, :gigs])
               |> Repo.all()

    render(conn, "merge_candidate_group.html", personas: personas)

  end


  def merge(conn, %{"from" => from, "to" => to}) do
    from_id = String.to_integer(from)
    to_id   = String.to_integer(to)

    from(e in Pan.Engagement, where: e.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(g in Pan.Gig, where: g.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(l in Pan.Like, where: l.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(f in Pan.Follow, where: f.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(p in Persona, where: p.redirect_id == ^from_id and
                              p.id != ^to_id)
    |> Repo.update_all(set: [redirect_id: to_id])

    from(p in Persona, where: p.redirect_id == ^from_id and
                              p.id == ^to_id)
    |> Repo.update_all(set: [redirect_id: nil])

    from(d in Pan.Delegation, where: d.persona_id == ^from_id and
                                 d.delegate_id != ^to_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(d in Pan.Delegation, where: d.delegate_id == ^from_id and
                                 d.persona_id != ^to_id)
    |> Repo.update_all(set: [delegate_id: to_id])

    from(d in Pan.Delegation, where: d.persona_id == ^from_id and
                                 d.delegate_id == ^to_id)
    |> Repo.delete_all()

    from(d in Pan.Delegation, where: d.persona_id == ^to_id and
                                 d.delegate_id == ^from_id)
    |> Repo.delete_all()

    from(m in Pan.Manifestation, where: m.persona_id == ^to_id)
    |> Repo.delete_all()

    Tirexs.HTTP.delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
                       "/personas/" <> Integer.to_string(from_id))

    Repo.get!(Persona, from_id)
    |> Repo.delete!

    conn
    |> put_flash(:info, "Personas merged successfully.")
    |> redirect(to: persona_path(conn, :merge_candidates))
  end
end