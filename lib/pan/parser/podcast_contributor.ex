defmodule Pan.Parser.PodcastContributor do
  import Ecto.Query
  alias Pan.Repo
  alias Pan.Parser.Persona
  alias PanWeb.Engagement

  def get_or_insert(podcast_contributor_map, role, podcast_id) do
    if podcast_contributor_map[:email] || podcast_contributor_map[:name] do
      {:ok, contributor} = Persona.get_or_insert(podcast_contributor_map)

      case Repo.get_by(PanWeb.Engagement,
             persona_id: contributor.id,
             podcast_id: podcast_id,
             role: role
           ) do
        nil ->
          %PanWeb.Engagement{persona_id: contributor.id, podcast_id: podcast_id, role: role}
          |> Repo.insert()

        engagement ->
          {:ok, engagement}
      end
    end
  end

  def delete_role(podcast_id, role) do
    from(e in Engagement,
      where:
        e.podcast_id == ^podcast_id and
          e.role == ^role
    )
    |> Repo.delete_all()
  end

  # "owner"/"managing editor"/"author" are proper delete-then-reinsert
  # singletons handled elsewhere (see Persistor.update_from_feed/2 and
  # Author), so they're excluded here. Rows for a *claimed* persona
  # (persona.user_id set — see PanWeb.Persona/Manifestation) are never
  # touched, regardless of role: a re-parse that doesn't re-match the exact
  # same Persona row (e.g. a name/email variant in the feed) must not
  # silently sever a real user's claimed contribution to this podcast.
  @reserved_roles ["owner", "managing editor", "author"]

  def delete_stale_feed_derived(podcast_id) do
    from(e in Engagement,
      join: p in assoc(e, :persona),
      where:
        e.podcast_id == ^podcast_id and
          e.role not in ^@reserved_roles and
          is_nil(p.user_id)
    )
    |> Repo.delete_all()
  end
end
