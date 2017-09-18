defmodule PanWeb.PersonaFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Persona
  alias PanWeb.Message
  alias PanWeb.Manifestation
  alias PanWeb.Gig
  alias PanWeb.Delegation
  alias PanWeb.Engagement
  alias PanWeb.Manifestation

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    personas = from(p in PanWeb.Persona, order_by: :name,
                                         where: is_nil(p.redirect_id))
               |> Repo.all()
    render(conn, "index.html", personas: personas)
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
                                       engagements: engagements)
        redirect_id ->
          persona = Repo.get!(Persona, redirect_id)
          redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
      end
    else
      render(conn, "not_found.html")
    end
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
            Persona.pro_user_changeset(persona, persona_params)
          else
            Persona.user_changeset(persona, persona_params)
          end

        case Repo.update(changeset) do
          {:ok, _persona} ->
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
end