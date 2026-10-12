defmodule PanWeb.PersonaController do
  use PanWeb, :controller
  alias PanWeb.{Delegation, Follow, Like, Persona, PageFrontendView}
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
    from_persona = Repo.get!(Persona, String.to_integer(from))
    to_persona = Repo.get!(Persona, String.to_integer(to))

    if from_persona.user_id && to_persona.user_id && from_persona.user_id != to_persona.user_id do
      conn
      |> put_flash(:error, "Both personas are owned by different users, not merged.")
      |> redirect(to: persona_path(conn, :merge_candidates))
    else
      # docs listing from's gigs/engagements will have to show to instead
      copy_ids = Search.Persona.copy_ids(from_persona.id)
      migrate_relations(from_persona.id, to_persona.id)
      inherit_attrs(to_persona, from_persona)

      Repo.delete!(from_persona)
      Search.Persona.delete_index(from_persona.id)
      Search.Persona.update_index(to_persona.id)
      Search.Persona.reset_copies(copy_ids)

      conn
      |> put_view(PageFrontendView)
      |> render("done.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    id = String.to_integer(id)
    # the persona's gigs/engagements go with it, docs still list them
    copy_ids = Search.Persona.copy_ids(id)

    Repo.transaction(fn ->
      persona = Repo.get!(Persona, id)

      from(p in Persona, where: p.redirect_id == ^id)
      |> Repo.update_all(set: [redirect_id: nil])

      from(l in Like, where: l.persona_id == ^id)
      |> Repo.delete_all()

      from(f in Follow, where: f.persona_id == ^id)
      |> Repo.delete_all()

      from(d in Delegation, where: d.persona_id == ^id or d.delegate_id == ^id)
      |> Repo.delete_all()

      Repo.delete!(persona)
    end)

    Search.Persona.delete_index(id)
    Search.Persona.reset_copies(copy_ids)

    conn
    |> put_view(PageFrontendView)
    |> put_flash(:info, "Persona deleted successfully.")
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

    # users claiming both personas keep their claim on to, the others' claims
    # move from from to to
    to_user_ids =
      from(m in PanWeb.Manifestation, where: m.persona_id == ^to_id, select: m.user_id)
      |> Repo.all()

    from(m in PanWeb.Manifestation, where: m.persona_id == ^from_id and m.user_id in ^to_user_ids)
    |> Repo.delete_all()

    from(m in PanWeb.Manifestation, where: m.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])
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
    [:uri, :email, :image_url, :image_title, :description, :long_description, :user_id]
    |> Enum.each(fn field ->
      from_val = Map.get(from_persona, field)

      if is_nil(Map.get(to_persona, field)) and not is_nil(from_val) do
        Persona.changeset(to_persona, %{field => from_val}) |> Repo.update()
      end
    end)
  end
end
