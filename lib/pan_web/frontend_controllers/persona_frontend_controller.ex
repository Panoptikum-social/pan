defmodule PanWeb.PersonaFrontendController do
  use Pan.Web, :controller
  alias PanWeb.{Delegation, Engagement, Gig, Image, Manifestation, Message, Persona}

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    render(conn, "index.html")
  end


  def datatable(conn, params, _user) do
    search = params["search"]["value"]
    searchfrag = "%#{params["search"]["value"]}%"

    limit = String.to_integer(params["length"])
    offset = String.to_integer(params["start"])
    draw = String.to_integer(params["draw"])

    columns = params["columns"]

    order_by = Enum.map(params["order"], fn({_key, value}) ->
                 column_number = value["column"]
                 {String.to_atom(value["dir"]), String.to_atom(columns[column_number]["data"])}
               end)

    records_total = Repo.aggregate(Persona, :count, :id)

    query =
      if search != "" do
        from(p in Persona, where: ilike(p.pid, ^searchfrag) or
                                  ilike(p.name, ^searchfrag) or
                                  ilike(fragment("cast (? as text)", p.id), ^searchfrag))
      else
        from(p in Persona)
      end

    records_filtered = query
                       |> Repo.aggregate(:count, :id)

    personas = from(p in query, limit: ^limit,
                                offset: ^offset,
                                order_by: ^order_by)
               |> Repo.all()

    render(conn, "datatable.json", personas: personas,
                                   draw: draw,
                                   records_total: records_total,
                                   records_filtered: records_filtered)

  end


  def show(conn, params, _user) do
    id = String.to_integer(params["id"])
    persona = Repo.get!(Persona, id)

    case persona.redirect_id do
      nil ->
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
      redirect_id ->
        persona = Repo.get!(Persona, redirect_id)
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
    end
  end


  def persona(conn, params, _user) do
    pid = params["pid"]
    persona = Repo.one(from p in Persona, where: p.pid == ^pid)

    if persona do
      delegator_ids = from(d in Delegation, where: d.delegate_id == ^persona.id,
                                            select: d.persona_id)
                      |> Repo.all
      persona_ids = [persona.id | delegator_ids]

      gigs = from(g in Gig, where: g.persona_id in ^persona_ids,
                            order_by: [desc: :publishing_date],
                            preload: [episode: :podcast])
             |> Repo.all()

      grouped_gigs = Enum.group_by(gigs, &Map.get(&1, :episode))

      engagements = from(e in Engagement, where: e.persona_id in ^persona_ids,
                                          preload: :podcast)
                    |> Repo.all()

      persona_thumbnail = Repo.get_by(Image, persona_id: persona.id)

      case persona.redirect_id do
        nil ->
          messages = from(m in Message, where: m.persona_id in ^persona_ids,
                                        order_by: [desc: :inserted_at],
                                        preload: :persona)
                     |> Repo.paginate(params)

          render(conn, "persona.html", persona: persona,
                                       messages: messages,
                                       gigs: gigs,
                                       grouped_gigs: grouped_gigs,
                                       engagements: engagements,
                                       persona_thumbnail: persona_thumbnail)
        redirect_id ->
          persona = Repo.get!(Persona, redirect_id)
          redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
      end
    else
      render(conn, "not_found.html")
    end
  end


  def business_card(conn, %{"id" => id}, _user) do
    persona = Repo.get!(Persona, id)

    conn
    |> put_layout("minimal.html")
    |> render("business_card.html", persona: persona)
  end


  def edit(conn, %{"id" => id}, user) do
    manifestation = from(m in Manifestation, where: m.user_id == ^user.id and m.persona_id == ^id,
                                             preload: :persona)
                    |> Repo.one()

    case manifestation do
      nil ->
        render(conn, "not_allowed.html")
      manifestation ->
        persona = manifestation.persona

        changeset = Persona.changeset(persona)
        render(conn, "edit.html", persona: persona, changeset: changeset)
    end
  end


  def update(conn, %{"id" => id, "persona" => persona_params}, user) do
    manifestation = from(m in Manifestation, where: m.user_id == ^user.id and m.persona_id == ^id,
                                             preload: :persona)
                    |> Repo.one()

    case manifestation do
      nil ->
        render(conn, "not_allowed.html")
      manifestation ->
        persona = manifestation.persona

        changeset =
          if user.pro_until && NaiveDateTime.compare(user.pro_until, NaiveDateTime.utc_now()) do
            thumbnail = from(i in Image, where: i.persona_id == ^id)
                        |> Repo.one()
            if thumbnail, do: Image.delete_asset(thumbnail)
            Image.download_thumbnail("persona", String.to_integer(id), persona_params["image_url"])

            Persona.pro_user_changeset(persona, persona_params)
          else
            Persona.user_changeset(persona, persona_params)
          end

require IEx; IEx.pry()

        case Repo.update(changeset) do
          {:ok, _persona} ->
            Persona.update_search_index(manifestation.persona.id)

            conn
            |> put_flash(:info, "Persona updated successfully.")
            |> redirect(to: user_frontend_path(conn, :my_profile))
          {:error, changeset} ->
            render(conn, "edit.html", persona: persona, changeset: changeset)
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

      Persona.delete_search_index(id)

      conn
      |> put_flash(:info, "Persona redirected successfully.")
      |> redirect(to: user_frontend_path(conn, :my_profile))
    else
      render(conn, "not_allowed.html")
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

      Persona.update_search_index(id)

      conn
      |> put_flash(:info, "Redirect cancelled successfully.")
      |> redirect(to: user_frontend_path(conn, :my_profile))
    else
      render(conn, "not_allowed.html")
    end
  end


  def toggle_delegation(conn, %{"id" => id, "delegate_id" => delegate_id}, user) do
    id = String.to_integer(id)
    delegate_id = String.to_integer(delegate_id)

    persona_ids = from(m in Manifestation, where: m.user_id == ^user.id,
                                           select: m.persona_id)
                  |> Repo.all()

    if id in persona_ids and delegate_id in persona_ids do
      case Repo.get_by(Delegation, persona_id: id,
                                   delegate_id: delegate_id) do
        nil ->
          %Delegation{persona_id: id,
                      delegate_id: delegate_id}
          |> Repo.insert

          conn
          |> put_flash(:info, "Persona delegated successfully.")
          |> redirect(to: user_frontend_path(conn, :my_profile))

        delegation ->
          Repo.delete!(delegation)

          conn
          |> put_flash(:info, "Delegation deleted successfully.")
          |> redirect(to: user_frontend_path(conn, :my_profile))
      end
    else
      render(conn, "not_allowed.html")
    end
  end


  def claim(conn, %{"id" => id}, user) do
    email = Repo.get(Persona, id).email

    PanWeb.Endpoint
    |> Phoenix.Token.sign("persona", id)
    |> Pan.Email.confirm_persona_claim_link_html_email(user, email)
    |> Pan.Mailer.deliver_now()

    render(conn, "email_sent.html")
  end


  def grant_access(conn, %{"id" => id, "token" => token}, _user) do
    user_id = String.to_integer(id)

    case PanWeb.Auth.grant_access_by_token(conn, token) do
      {:ok, persona_id} ->
        case Repo.get_by(Manifestation, user_id: user_id,
                                        persona_id: persona_id) do
          nil ->
            %Manifestation{user_id: user_id,
                           persona_id: persona_id}
            |> Repo.insert

            conn
            |> put_flash(:info, "Access has been granted successfully!")
            |> render("grant_access.html")

          _delegation ->
            conn
            |> put_flash(:info, "Access was already in place!")
            |> render("grant_access.html")
        end
      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> render("grant_access.html")
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("grant_access.html")
    end
  end


  def warning(conn, %{"id" => id}, _user) do
    persona = Repo.get(Persona, id)

    render(conn, "warning.html", persona: persona)
  end


  def connect(conn, %{"id" => id}, user) do
    persona = Repo.get(Persona, id)

    if user.podcaster && user.email_confirmed && !persona.email do
      persona
      |> PanWeb.Persona.claiming_changeset(%{user_id: user.id,
                                             email: user.email})
      |> Repo.update()

      %Manifestation{user_id: user.id,
                     persona_id: persona.id}
      |> Repo.insert

      conn
      |> put_flash(:info, "Persona claimed  successfully.")
      |> redirect(to: persona_frontend_path(conn, :show, persona))
    else
      conn
      |> put_flash(:error, "You are not allowed to claim this persona!")
      |> render("warning.html", persona: persona)
    end
  end


  def disconnect(conn, %{"id" => id}, user) do
    from(r in Persona, where: r.id == ^id and r.user_id == ^user.id)
    |> Repo.one()
    |> PanWeb.Persona.claiming_changeset(%{user_id: nil,
                                           email: nil})
    |> Repo.update()

    conn
    |> put_flash(:info, "Persona disconnected successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end