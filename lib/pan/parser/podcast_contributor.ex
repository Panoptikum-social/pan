defmodule Pan.Parser.PodcastContributor do
  use Pan.Web, :controller
  alias Pan.Parser.Persona
  alias PanWeb.Engagement

  def get_or_insert(podcast_contributor_map, role, podcast_id) do
    if podcast_contributor_map[:email] || podcast_contributor_map[:name] do
      {:ok, contributor} = Persona.get_or_insert(podcast_contributor_map)


      case Repo.get_by(PanWeb.Engagement, persona_id: contributor.id,
                                          podcast_id: podcast_id,
                                          role: role) do
        nil ->
          %PanWeb.Engagement{persona_id: contributor.id,
                             podcast_id: podcast_id,
                             role: role}
          |> Repo.insert()
        engagement ->
          {:ok, engagement}
      end
    end
  end


  def delete_role(podcast_id, role) do
    (from e in Engagement, where: e.podcast_id == ^podcast_id and
                                  e.role == ^role)
    |> Repo.delete_all()
  end
end