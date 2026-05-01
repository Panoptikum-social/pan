defmodule PanWeb.PersonaController do
  use PanWeb, :controller
  alias PanWeb.{Persona, PageFrontendView}
  alias Pan.Search

  def merge_candidates(conn, _params) do
    non_unique_names =
      from(p in Persona,
        group_by: p.name,
        having: count(p.id) > 1,
        select: {p.name, count(p.id)},
        order_by: p.name
      )
      |> Repo.all()

    non_unique_emails =
      from(p in Persona,
        group_by: p.email,
        having: count(p.id) > 1,
        select: {p.email, count(p.id)},
        order_by: p.email
      )
      |> Repo.all()

    render(conn, "merge_candidates.html",
      non_unique_names: non_unique_names,
      non_unique_emails: non_unique_emails
    )
  end

  def merge_candidate_group(conn, %{"name" => name}) do
    personas =
      from(p in Persona,
        where: p.name == ^name,
        preload: [:engagements, :gigs]
      )
      |> Repo.all()

    render(conn, "merge_candidate_group.html", personas: personas)
  end

  def merge_candidate_group(conn, %{"email" => email}) do
    personas =
      from(p in Persona,
        where: p.email == ^email,
        preload: [:engagements, :gigs]
      )
      |> Repo.all()

    render(conn, "merge_candidate_group.html", personas: personas)
  end

  def merge(conn, %{"from" => from, "to" => to}) do
    from_id = String.to_integer(from)
    to_id = String.to_integer(to)

    migrate_relations(from_id, to_id)

    to_persona = Repo.get!(Persona, to_id)
    from_persona = Repo.get!(Persona, from_id)

    inherit_attrs(to_persona, from_persona)

    Repo.delete!(from_persona)
    Search.Persona.delete_index(from_id)
    Search.Persona.update_index(to_id)

    conn
    |> put_view(PageFrontendView)
    |> render("done.html")
  end

  defp migrate_relations(from_id, to_id) do
    from(e in PanWeb.Engagement, where: e.persona_id == ^from_id)
    |> Repo.all()
    |> Enum.each(&migrate_engagement(&1, to_id))

    from(g in PanWeb.Gig, where: g.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(l in PanWeb.Like, where: l.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(f in PanWeb.Follow, where: f.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(p in Persona, where: p.redirect_id == ^from_id and p.id != ^to_id)
    |> Repo.update_all(set: [redirect_id: to_id])

    from(p in Persona, where: p.redirect_id == ^from_id and p.id == ^to_id)
    |> Repo.update_all(set: [redirect_id: nil])

    from(d in PanWeb.Delegation, where: d.persona_id == ^from_id and d.delegate_id != ^to_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(d in PanWeb.Delegation, where: d.delegate_id == ^from_id and d.persona_id != ^to_id)
    |> Repo.update_all(set: [delegate_id: to_id])

    from(d in PanWeb.Delegation, where: d.persona_id == ^from_id and d.delegate_id == ^to_id)
    |> Repo.delete_all()

    from(d in PanWeb.Delegation, where: d.persona_id == ^to_id and d.delegate_id == ^from_id)
    |> Repo.delete_all()

    from(m in PanWeb.Manifestation, where: m.persona_id == ^to_id)
    |> Repo.delete_all()

    Pan.Search.Persona.delete_index(from_id)
  end

  defp migrate_engagement(engagement, to_id) do
    case Repo.get_by(PanWeb.Engagement,
           persona_id: to_id,
           podcast_id: engagement.podcast_id,
           role: engagement.role
         ) do
      nil -> PanWeb.Engagement.changeset(engagement, %{persona_id: to_id}) |> Repo.update()
      _ -> Repo.delete!(engagement)
    end
  end

  defp inherit_attrs(to_persona, from_persona) do
    [:uri, :email, :image_url, :image_title, :description, :long_description]
    |> Enum.each(fn field ->
      from_val = Map.get(from_persona, field)

      if is_nil(Map.get(to_persona, field)) and not is_nil(from_val) do
        Persona.changeset(to_persona, %{field => from_val}) |> Repo.update()
      end
    end)
  end
end
