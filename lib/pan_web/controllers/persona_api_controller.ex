defmodule PanWeb.PersonaApiController do
  use Pan.Web, :controller
  alias PanWeb.Persona
  alias PanWeb.Gig
  alias PanWeb.Engagement
  alias PanWeb.Delegation
  alias PanWeb.Podcast
  alias PanWeb.Episode
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

    total = from(g in PanWeb.Gig, where: g.persona_id == ^id)
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
                                        include: "redirect,delegates,engagements,gigs,podcasts,episodes"]
  end


    def search(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment) <> "/personas",
             search: [size: size, from: offset, query: [match: [_all: params["filter"]]]]]


    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits}} ->
        total = Enum.min([hits.total, 10000])
        total_pages = div(total - 1, size) + 1


        links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                             size: size,
                                                             total: total_pages,
                                                             base_url: persona_api_url(conn,:search)}, conn)

        persona_ids = Enum.map(hits[:hits], fn(hit) -> String.to_integer(hit[:_id]) end)

        personas = from(p in Persona, where: p.id in ^persona_ids,
                                      preload: [:redirect, :delegates, :podcasts])
                   |> Repo.all()

        render conn, "index.json-api", data: personas, opts: [page: links,
                                                              include: "redirect,delegates,podcasts"]
      {:error, 500, %{error: %{caused_by: %{reason: reason}}}} ->
        render(conn, "error.json-api", reason: reason)
    end
  end
end
