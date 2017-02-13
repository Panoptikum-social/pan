defmodule Pan.MaintenanceController do
  use Pan.Web, :controller
  alias Pan.CategoryPodcast
  alias Pan.Subscription
  alias Pan.Message
  alias Pan.Gig
  alias Pan.Engagement
  alias Pan.Podcast
  alias Pan.Persona
  alias Pan.Gig
  alias Pan.Episode

  def remove_duplicates(conn, _params) do
    duplicates = from(a in CategoryPodcast, group_by: [a.category_id, a.podcast_id],
                                            select: [a.category_id, a.podcast_id, count(a.podcast_id)],
                                            having: count(a.podcast_id) > 1)
                 |> Repo.all()

    for [category_id, podcast_id, _count] <- duplicates do
      from(a in CategoryPodcast, where: a.category_id == ^category_id and
                                        a.podcast_id == ^podcast_id)
      |> Repo.delete_all()

      Repo.insert!(%CategoryPodcast{podcast_id: podcast_id,
                                    category_id: category_id})
    end

    duplicates = from(a in Subscription, group_by: [a.user_id, a.podcast_id],
                                         select: [a.user_id, a.podcast_id, count(a.podcast_id)],
                                         having: count(a.podcast_id) > 1)
                 |> Repo.all()

    for [user_id, podcast_id, _count] <- duplicates do
      from(a in Subscription, where: a.user_id == ^user_id and
                                     a.podcast_id == ^podcast_id)
      |> Repo.delete_all()

      Repo.insert!(%Subscription{podcast_id: podcast_id,
                                 user_id: user_id})
    end

    render(conn, "remove_duplicates.html", %{})
  end


  def message_cleanup(conn, _params) do
    from(m in Message, where: m.event in ["follow", "subscribe"])
    |> Repo.delete_all()

    render(conn, "message_cleanup.html", %{})
  end


  def remove_duplicate_gigs(conn, _params) do
    duplicates = from(g in Gig, group_by: [g.role, g.episode_id, g.persona_id,],
                                select: [g.role, g.episode_id, g.persona_id, count(g.persona_id)],
                                having: count(g.persona_id) > 1)
                 |> Repo.all()

    for [role, episode_id, persona_id, count] <- duplicates do
      one_less = count - 1

      gig_ids = from(g in Gig, where: g.role == ^role and
                                      g.episode_id == ^episode_id and
                                      g.persona_id == ^persona_id,
                               limit: ^one_less,
                               order_by: [asc: g.inserted_at],
                               select: g.id)
                    |> Repo.all()

      from(g in Gig, where: g.id in ^gig_ids)
      |> Repo.delete_all()
    end

    render(conn, "remove_duplicates.html")
  end


  def convert_authors(conn, _params) do
    # eliminate Jane Doe
    from(e in Engagement, where: e.persona_id == 191)
    |> Repo.delete_all()

    from(g in Gig, where: g.persona_id == 191)
    |> Repo.delete_all()

    from(p in Persona, where: p.id == 191)
    |> Repo.delete_all()


    # convert podcast authors
    podcasts = Repo.all(Podcast)

    for podcast <- podcasts do
      if podcast.author do
        persona_id = from(e in Engagement, where: e.podcast_id == ^podcast.id and
                                                  e.role == "owner",
                                         select: e.persona_id,
                                         limit: 1)
                     |> Repo.all()
                     |> List.first()
        persona =
          if persona_id do
            Repo.get!(Persona, persona_id)
          else
            %Persona{}
          end

        if podcast.author == persona.name do
          case Repo.get_by(Engagement, persona_id: persona.id,
                                       podcast_id: podcast.id,
                                       role: "author") do
            nil ->
              %Engagement{podcast_id: podcast.id,
                          persona_id: persona.id,
                          role: "author"}
              |> Repo.insert()
            engagement ->
              {:ok, engagement}
          end
        else
          persona_map = %{ uri: UUID.uuid5(:url, podcast.author),
                           name: podcast.author,
                           email: persona.email,
                           pid: UUID.uuid5(:url, podcast.author)}

          {:ok, persona} =
            case Repo.get_by(Pan.Persona, pid:   persona_map[:pid]) ||
                 Repo.get_by(Pan.Persona, pid:   persona_map[:uri]) ||
                 Repo.get_by(Pan.Persona, uri:   persona_map[:uri]) do
              nil ->
                %Pan.Persona{}
                |> Map.merge(persona_map)
                |> Repo.insert()
              persona ->
                {:ok, persona}
            end

          case Repo.get_by(Engagement, persona_id: persona.id,
                                       podcast_id: podcast.id,
                                       role: "author") do
            nil ->
              %Engagement{podcast_id: podcast.id,
                          persona_id: persona.id,
                          role: "author"}
              |> Repo.insert()
            engagement ->
              {:ok, engagement}
          end
        end
      end
    end

    # convert episode authors
    episodes = Repo.all(Episode)
               |> Repo.preload(:podcast)

    for episode <- episodes do
      if episode.author do
        persona_id = from(e in Engagement, where: e.podcast_id == ^episode.podcast.id and
                                                  e.role == "owner",
                                         select: e.persona_id,
                                         limit: 1)
                     |> Repo.all()
                     |> List.first()
        persona =
          if persona_id do
            Repo.get!(Persona, persona_id)
          else
            %Persona{}
          end

        if episode.author == persona.name do
          case Repo.get_by(Gig, persona_id: persona.id,
                                episode_id: episode.id,
                                role: "author") do
            nil ->
              %Gig{episode_id: episode.id,
                   persona_id: persona.id,
                   role: "author",
                   publishing_date: episode.publishing_date}
              |> Repo.insert()
            gig ->
              {:ok, gig}
          end
        else
          persona_map = %{ uri: UUID.uuid5(:url, episode.author),
                           name: episode.author,
                           email: persona.email,
                           pid: UUID.uuid5(:url, episode.author)}

          {:ok, persona} =
            case Repo.get_by(Pan.Persona, pid: persona_map[:pid]) ||
                 Repo.get_by(Pan.Persona, pid: persona_map[:uri]) ||
                 Repo.get_by(Pan.Persona, uri: persona_map[:uri]) do
              nil ->
                %Pan.Persona{}
                |> Map.merge(persona_map)
                |> Repo.insert()
              persona ->
                {:ok, persona}
            end

          case Repo.get_by(Gig, persona_id: persona.id,
                                episode_id: episode.id,
                                role: "author") do
            nil ->
              %Gig{episode_id: episode.id,
                   persona_id: persona.id,
                   role: "author",
                   publishing_date: episode.publishing_date}
              |> Repo.insert()
            gig ->
              {:ok, gig}
          end
        end
      end
    end

    render(conn, "done.html")
  end
end
