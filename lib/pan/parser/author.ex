defmodule Pan.Parser.Author do
  use Pan.Web, :controller
  alias Pan.Parser.Persona
  alias Pan.Engagement
  alias Pan.Gig

  def get_or_insert_persona_and_engagement(author_map, podcast_id) do
    if author_map[:email] || author_map[:name] do
      engagement = from(e in Engagement, where: e.podcast_id == ^podcast_id and
                                                e.role == "owner",
                                         limit: 1)
                   |> Repo.one()
                   |> Repo.preload(:persona)

      {:ok, author} =
        if engagement && engagement.persona.name == author_map[:name] do
          {:ok, engagement.persona}
        else
          Persona.get_or_insert(author_map)
        end

      case Repo.get_by(Engagement, persona_id: author.id,
                                   podcast_id: podcast_id,
                                   role: "author") do
        nil ->
          %Engagement{persona_id: author.id,
                      podcast_id: podcast_id,
                      role: "author"}
          |> Repo.insert()
        engagement ->
          {:ok, engagement}
      end
    end
  end


  def get_or_insert_persona_and_gig(author_map, episode, podcast) do
    if author_map[:email] || author_map[:name] do
      engagement = from(e in Engagement, where: e.podcast_id == ^podcast.id and
                                                e.role == "author",
                                         limit: 1)
                   |> Repo.one()
                   |> Repo.preload(:persona)

      {:ok, author} =
        if engagement && engagement.persona.name == author_map[:name] do
          {:ok, engagement.persona}
        else
          Persona.get_or_insert(author_map)
        end

      case Repo.get_by(Gig, persona_id: author.id,
                            episode_id: episode.id,
                            role: "author") do
        nil ->
          %Gig{persona_id: author.id,
               episode_id: episode.id,
               role: "author",
               publishing_date: episode.publishing_date}
          |> Repo.insert()
        gig ->
          {:ok, gig}
      end
    end
  end
end