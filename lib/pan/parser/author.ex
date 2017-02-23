defmodule Pan.Parser.Author do
  use Pan.Web, :controller
  alias Pan.Persona
  alias Pan.Engagement
  alias Pan.Gig

  def get_or_insert_into_podcast(author, podcast_id) do
    if author do
      persona_id = from(e in Engagement, where: e.podcast_id == ^podcast_id and
                                                e.role == "owner",
                                         select: e.persona_id,
                                         limit: 1)
                   |> Repo.all()
                   |> List.first()

      persona = if persona_id, do: Repo.get!(Persona, persona_id), else: %Persona{}

      if author == persona.name do
        get_or_insert_engagement_as_author(persona.id, podcast_id)
      else
        persona_map = %{uri: UUID.uuid5(:url, author),
                        name: author,
                        email: persona.email,
                        pid: UUID.uuid5(:url, author)}

        {:ok, persona} = case Repo.get_by(Persona, pid: persona_map[:pid]) ||
                              Repo.get_by(Persona, pid: persona_map[:uri]) ||
                              Repo.get_by(Persona, uri: persona_map[:uri]) do
                           nil ->
                             %Persona{}
                             |> Map.merge(persona_map)
                             |> Repo.insert()
                           persona ->
                             {:ok, persona}
                         end

        get_or_insert_engagement_as_author(persona.id, podcast_id)
      end
    end
  end


  def get_or_insert_engagement_as_author(persona_id, podcast_id) do
    case Repo.get_by(Engagement, persona_id: persona_id,
                                 podcast_id: podcast_id,
                                 role: "author") do
      nil ->
        %Engagement{podcast_id: podcast_id,
                    persona_id: persona_id,
                    role: "author"}
        |> Repo.insert()
      engagement ->
        {:ok, engagement}
    end
  end


  def get_or_insert_into_episode(author, episode, podcast) do
    if author do
      persona_id = from(e in Engagement, where: e.podcast_id == ^podcast.id and
                                                e.role == "owner",
                                         select: e.persona_id,
                                         limit: 1)
                   |> Repo.all()
                   |> List.first()

      persona = if persona_id, do: Repo.get!(Persona, persona_id), else: %Persona{}

      if author == persona.name do
        get_or_insert_gig_as_author(persona.id, episode)
      else
        persona_map = %{uri: UUID.uuid5(:url, episode.author),
                        name: episode.author,
                        email: persona.email,
                        pid: UUID.uuid5(:url, episode.author)}

        {:ok, persona} =
          case Repo.get_by(Persona, pid: persona_map[:pid]) ||
               Repo.get_by(Persona, pid: persona_map[:uri]) ||
               Repo.get_by(Persona, uri: persona_map[:uri]) do
            nil ->
              %Persona{}
              |> Map.merge(persona_map)
              |> Repo.insert()
            persona ->
              {:ok, persona}
          end

        get_or_insert_gig_as_author(persona.id, episode)
      end
    end
  end


  def get_or_insert_gig_as_author(persona_id, episode) do
    case Repo.get_by(Gig, persona_id: persona_id,
                          episode_id: episode.id,
                          role: "author") do
      nil ->
        %Gig{episode_id: episode.id,
             persona_id: persona_id,
             role: "author",
             publishing_date: episode.publishing_date}
        |> Repo.insert()
      gig ->
        {:ok, gig}
    end
  end
end