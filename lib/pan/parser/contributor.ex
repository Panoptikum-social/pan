defmodule Pan.Parser.Contributor do
  import Ecto.Query
  alias Pan.Repo
  alias Pan.Parser.Persona
  alias PanWeb.{Engagement, Gig}

  def persist_many(nil, _), do: nil

  def persist_many(contributors_map, %PanWeb.Podcast{} = podcast) do
    for {_, contributor_map} <- contributors_map do
      role = contributor_map[:role] || "contributor"
      {:ok, contributor} = Persona.get_or_insert(Map.delete(contributor_map, :role))

      case Repo.get_by(Engagement,
             persona_id: contributor.id,
             podcast_id: podcast.id,
             role: role
           ) do
        nil ->
          %Engagement{persona_id: contributor.id, podcast_id: podcast.id, role: role}
          |> Repo.insert()

        engagement ->
          {:ok, engagement}
      end
    end
  end

  def persist_many(contributors_map, %PanWeb.Episode{} = episode) do
    for {_, contributor_map} <- contributors_map do
      role = contributor_map[:role] || "contributor"
      {:ok, contributor} = Persona.get_or_insert(Map.delete(contributor_map, :role))

      case Repo.get_by(Gig,
             persona_id: contributor.id,
             episode_id: episode.id,
             role: role
           ) do
        nil ->
          %Gig{
            persona_id: contributor.id,
            episode_id: episode.id,
            role: role,
            publishing_date: episode.publishing_date
          }
          |> Repo.insert()

        gig ->
          {:ok, gig}
      end
    end
  end

  def delete_role(episode_id, role) do
    from(g in Gig,
      where:
        g.episode_id == ^episode_id and
          g.role == ^role
    )
    |> Repo.delete_all()
  end

  # "author" is a proper delete-then-reinsert singleton handled elsewhere
  # (see Author.get_or_insert_persona_and_gig/3), so it's excluded here. Two
  # kinds of rows are never touched, regardless of role: a *claimed* persona's
  # (persona.user_id set) — a re-parse that doesn't re-match the exact same
  # Persona row must not silently sever a real user's claimed contribution —
  # and any `self_proclaimed: true` row (Gig.proclaim/3), which isn't
  # feed-derived at all and was already being wiped by the old delete_role
  # call on every re-parse, a separate bug fixed here in passing.
  @reserved_roles ["author"]

  def delete_stale_feed_derived(episode_id) do
    from(g in Gig,
      join: p in assoc(g, :persona),
      where:
        g.episode_id == ^episode_id and
          g.role not in ^@reserved_roles and
          g.self_proclaimed == false and
          is_nil(p.user_id)
    )
    |> Repo.delete_all()
  end
end
