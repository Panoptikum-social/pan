defmodule PanWeb.Api.PersonaController do
  use PanWeb, :controller

  alias PanWeb.{
    Api.Helpers,
    Api.ErrorView,
    Delegation,
    Engagement,
    Episode,
    Gig,
    Manifestation,
    Persona,
    Podcast
  }

  use JaSerializer

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, params, _user) do
    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total = Repo.aggregate(Persona, :count, :id)
    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_user_url(:index)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    personas =
      from(p in Persona,
        order_by: :name,
        limit: ^size,
        offset: ^offset,
        preload: :redirect
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: personas,
      opts: [page: links, include: "redirect"]
    )
  end

  def show(conn, %{"id" => id} = params, _user) do
    delegator_ids =
      from(d in Delegation,
        where: d.delegate_id == ^id,
        select: d.persona_id
      )
      |> Repo.all()

    persona_ids = [id | delegator_ids]

    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total =
      from(g in PanWeb.Gig, where: g.persona_id == ^id)
      |> Repo.aggregate(:count)

    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_persona_url(:show, id)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    persona =
      Repo.get(Persona, id)
      |> Repo.preload([:redirect, :delegates, :podcasts])

    gigs =
      from(g in Gig,
        where: g.persona_id in ^persona_ids,
        order_by: [desc: g.publishing_date],
        offset: ^offset,
        limit: ^size
      )
      |> Repo.all()

    episodes =
      from(e in Episode,
        join: g in assoc(e, :gigs),
        where: g.persona_id in ^persona_ids,
        order_by: [desc: g.publishing_date],
        offset: ^offset,
        limit: ^size
      )
      |> Repo.all()

    engagements =
      from(e in Engagement, where: e.persona_id in ^persona_ids)
      |> Repo.all()

    podcasts =
      from(p in Podcast,
        join: e in assoc(p, :engagements),
        where: e.persona_id in ^persona_ids
      )
      |> Repo.all()

    if persona do
      persona =
        struct(persona,
          gigs: gigs,
          engagements: engagements,
          podcasts: podcasts,
          episodes: episodes
        )

      render(conn, "show.json-api",
        data: persona,
        gigs: gigs,
        engagements: engagements,
        opts: [page: links, include: "redirect,delegates,engagements,gigs,podcasts,episodes"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def search(conn, params, _user) do
    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    hits = Pan.Search.query(index: "personas", term: params["filter"], limit: size, offset: offset)

    if hits["total"] > 0 do
      total = Enum.min([hits["total"], 10_000])
      total_pages = div(total - 1, size) + 1

      links =
        conn
        |> api_persona_url(:search)
        |> Helpers.pagination_links({page, size, total_pages}, conn)

      persona_ids = Enum.map(hits["hits"], fn hit -> String.to_integer(hit["_id"]) end)

      personas =
        from(p in Persona,
          where: p.id in ^persona_ids,
          preload: [:redirect, :delegates, :podcasts]
        )
        |> Repo.all()

      render(conn, "index.json-api",
        data: personas,
        opts: [page: links, include: "redirect,delegates,podcasts"]
      )
    else
      Helpers.send_error(
        conn,
        404,
        "Nothing found",
        "No matching personas found in the data base."
      )
    end
  end

  def update(conn, %{"id" => id} = params, user) do
    manifestation =
      from(m in Manifestation,
        where: m.user_id == ^user.id and m.persona_id == ^id,
        preload: :persona
      )
      |> Repo.one()

    case manifestation do
      nil ->
        Helpers.send_401(conn, "You are not a manifestation of this persona.")

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
    manifestation =
      from(m in Manifestation,
        where: m.user_id == ^user.id and m.persona_id == ^id,
        preload: :persona
      )
      |> Repo.one()

    case manifestation do
      nil ->
        Helpers.send_401(conn, "You are not a manifestation of of this persona.")

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

    with %PanWeb.Persona{} <- Repo.get(Persona, id),
         %PanWeb.Persona{} <- Repo.get(Persona, target_id),
         true <- target_id != id do
      persona_ids =
        from(m in Manifestation,
          where: m.user_id == ^user.id,
          select: m.persona_id
        )
        |> Repo.all()

      if id in persona_ids && target_id in persona_ids do
        from(p in Persona, where: p.id == ^id)
        |> Repo.update_all(set: [redirect_id: target_id])

        show(conn, %{"id" => id}, user)
      else
        Helpers.send_401(conn, "You are not a manifestation of both of this personas.")
      end
    else
      nil ->
        Helpers.send_404(conn)

      false ->
        Helpers.send_error(
          conn,
          412,
          "Precondition Failed",
          "redirects can only happen between different personas"
        )
    end
  end

  def cancel_redirect(conn, %{"id" => id}, user) do
    id = String.to_integer(id)

    persona_ids =
      from(m in Manifestation,
        where: m.user_id == ^user.id,
        select: m.persona_id
      )
      |> Repo.all()

    if id in persona_ids do
      from(p in Persona, where: p.id == ^id)
      |> Repo.update_all(set: [redirect_id: nil])

      show(conn, %{"id" => id}, user)
    else
      Helpers.send_401(conn, "You are not a manifestation of this persona.")
    end
  end

  def claim(conn, %{"id" => id}, user) do
    case persona = Repo.get(Persona, id) do
      %PanWeb.Persona{} ->
        if persona.email do
          PanWeb.Endpoint
          |> Phoenix.Token.sign("persona", id)
          |> Pan.Email.confirm_persona_claim_link_html_email(user, persona.email)
          |> Pan.Mailer.deliver_now!

          conn
          |> put_view(ErrorView)
          |> put_status(200)
          |> render(:errors,
            data: %{
              code: 200,
              status: 200,
              title: "OK",
              detail: "An Email to the Persona has been sent"
            }
          )
        else
          Helpers.send_401(conn, "You are not a manifestation of both of this personas.")
        end

      nil ->
        Helpers.send_404(conn)
    end
  end
end
