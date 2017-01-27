defmodule Pan.PersonaFrontendController do
  use Pan.Web, :controller
  alias Pan.Persona
  alias Pan.Message
  alias Pan.Manifestation
  alias Pan.Gig
  alias Pan.Delegation


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    personas = Repo.all(from p in Pan.Persona, order_by: :name,
                                               where: is_nil(p.redirect_id))
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
              |> Repo.preload(gigs: from(g in Gig, order_by: [desc: :publishing_date],
                                                   preload: :episode))
              |> Repo.preload(engagements: :podcast)

    case persona.redirect_id do
      nil ->
        messages = from(m in Message, where: m.persona_id == ^persona.id,
                                      order_by: [desc: :inserted_at],
                                      preload: :persona)
                   |> Repo.paginate(params)

        render(conn, "persona.html", persona: persona, messages: messages)
      redirect_id ->
        persona = Repo.get!(Persona, redirect_id)
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
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
        changeset = Persona.changeset(persona, persona_params)

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

    if (id in persona_ids and target_id in persona_ids) do
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

    if (id in persona_ids) do
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

    if (id in persona_ids and delegate_id in persona_ids) do
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
end