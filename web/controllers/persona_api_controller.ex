defmodule Pan.PersonaApiController do
  use Pan.Web, :controller
  alias Pan.Persona
  alias Pan.Gig
  alias Pan.Engagement
  alias Pan.Delegation
  alias Pan.Podcast
  alias Pan.Episode
  use JaSerializer

  def show(conn, %{"id" => id} = params) do
    delegator_ids = from(d in Delegation, where: d.delegate_id == ^id,
                                          select: d.persona_id)
                    |> Repo.all
    persona_ids = [id | delegator_ids]

    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(g in Pan.Gig, where: g.persona_id == ^id)
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: persona_api_url(conn,:show, id)}, conn)

    persona = Repo.get(Persona, id)
              |> Repo.preload([:redirect, :delegates, :podcasts])

    gigs = from(g in Gig, where: g.persona_id in ^persona_ids,
                          order_by: [desc: g.publishing_date],
                          offset: ^offset,
                          limit: ^size)
           |> Repo.all()

    episodes = from(e in Episode, join: g in assoc(e, :gigs),
                                  where: g.persona_id in ^persona_ids,
                                  order_by: [desc: g.publishing_date],
                                  offset: ^offset,
                                  limit: ^size)
           |> Repo.all()


    engagements = from(e in Engagement, where: e.persona_id in ^persona_ids)
                  |> Repo.all()

    podcasts = from(p in Podcast, join: e in assoc(p, :engagements),
                                  where: e.persona_id in ^persona_ids)
               |> Repo.all()

    persona = persona
              |> Map.put(:gigs, gigs)
              |> Map.put(:engagements, engagements)
              |> Map.put(:podcasts, podcasts)
              |> Map.put(:episodes, episodes)

    render conn, "show.json-api", data: persona,
                                  gigs: gigs,
                                  engagements: engagements,
                                  opts: [page: links,
                                        include: "rediect,delegates,engagements,gigs,podcasts,episodes"]
  end
end
