defmodule Pan.Parser.Contributor do
  use Pan.Web, :controller
  alias Pan.Parser.Persona
  alias PanWeb.Gig
  alias PanWeb.Engagement


  def persist_many(contributors_map, %PanWeb.Podcast{} = podcast) do
    if contributors_map do
      for {_, contributor_map} <- contributors_map do
        {:ok, contributor} = Persona.get_or_insert(contributor_map)

        case Repo.get_by(Engagement, persona_id: contributor.id,
                                     podcast_id: podcast.id,
                                     role: "contributor") do
          nil ->
            %Engagement{persona_id: contributor.id,
                        podcast_id: podcast.id,
                        role: "contributor"}
            |> Repo.insert()
          engagement ->
            {:ok, engagement}
        end
      end
    end
  end


  def persist_many(contributors_map, %PanWeb.Episode{} = episode) do
    if contributors_map do
      for {_, contributor_map} <- contributors_map do
        {:ok, contributor} = Persona.get_or_insert(contributor_map)

        case Repo.get_by(Gig, persona_id: contributor.id,
                              episode_id: episode.id,
                              role: "contributor") do
          nil ->
            %Gig{persona_id: contributor.id,
                 episode_id: episode.id,
                 role: "contributor",
                 publishing_date: episode.publishing_date}
            |> Repo.insert()
          gig ->
            {:ok, gig}
        end
      end
    end
  end
end
