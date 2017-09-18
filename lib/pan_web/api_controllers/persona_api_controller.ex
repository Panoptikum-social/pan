defmodule PanWeb.PersonaApiController do
  use Pan.Web, :controller
  alias PanWeb.Persona
  alias PanWeb.Gig
  alias PanWeb.Engagement
  alias PanWeb.Delegation
  alias PanWeb.Podcast
  alias PanWeb.Episode
  alias PanWeb.Manifestation
  use JaSerializer
  import PanWeb.ApiAuth, only: [send_error: 2]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = Repo.aggregate(Persona, :count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: user_api_url(conn,:index)}, conn)

    personas = from(p in Persona, order_by: :name,
                                  limit: ^size,
                                  offset: ^offset,
                                  preload: :redirect)
               |> Repo.all()


    render conn, "index.json-api", data: personas,
                                   opts: [page: links, include: "redirect"]
  end


  def show(conn, %{"id" => id} = params, _user) do
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


  def search(conn, params, _user) do
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
        send_error(conn, reason)
    end
  end


  def update(conn, %{"id" => id} = params, user) do
    manifestation = from(m in Manifestation, where: m.user_id == ^user.id and m.persona_id == ^id,
                                             preload: :persona)
                    |> Repo.one()

    case manifestation do
      nil ->
        send_error(conn, "You are not a manifestation of both of this personas.")
      manifestation ->
        persona = manifestation.persona
        changeset = Persona.user_changeset(persona, params)

        case Repo.update(changeset) do
          {:ok, persona} ->
            show(conn, %{"id" => persona.id}, user)
          {:error, changeset} ->
            conn
            |> put_status(422)
            |> render(:errors, data: changeset)
        end
    end
  end


  def pro_update(conn, %{"id" => id} = params, user) do
    manifestation = from(m in Manifestation, where: m.user_id == ^user.id and m.persona_id == ^id,
                                             preload: :persona)
                    |> Repo.one()

    case manifestation do
      nil ->
        send_error(conn, "You are not a manifestation of both of this personas.")
      manifestation ->
        persona = manifestation.persona
        changeset = Persona.pro_user_changeset(persona, params)

        case Repo.update(changeset) do
          {:ok, persona} ->
            show(conn, %{"id" => persona.id}, user)
          {:error, changeset} ->
            conn
            |> put_status(422)
            |> render(:errors, data: changeset)
        end
    end
  end


  def redirect(conn, %{"id" => id, "target_id" => target_id}, user) do
    id = String.to_integer(id)
    target_id = String.to_integer(target_id)

    persona_ids = from(m in Manifestation, where: m.user_id == ^user.id,
                                           select: m.persona_id)
                  |> Repo.all()

    if id in persona_ids && target_id in persona_ids do
      from(p in Persona, where: p.id == ^id)
      |> Repo.update_all(set: [redirect_id: target_id])

      show(conn, %{"id" => id}, user)
    else
      send_error(conn, "You are not a manifestation of both of this personas.")
    end
  end


  def cancel_redirect(conn, %{"id" => id}, user) do
    id = String.to_integer(id)

    persona_ids = from(m in Manifestation, where: m.user_id == ^user.id,
                                           select: m.persona_id)
                  |> Repo.all()

    if id in persona_ids do
      from(p in Persona, where: p.id == ^id)
      |> Repo.update_all(set: [redirect_id: nil])

      show(conn, %{"id" => id}, user)
    else
      send_error(conn, "You are not a manifestation of both of this personas.")
    end
  end
end
