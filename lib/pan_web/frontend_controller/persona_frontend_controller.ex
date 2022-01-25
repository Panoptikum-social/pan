defmodule PanWeb.PersonaFrontendController do
  use PanWeb, :controller
  alias Pan.Search
  alias PanWeb.{Delegation, Manifestation, Persona}

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, _user) do
    persona = Repo.get!(Persona, id)

    case persona.redirect_id do
      nil ->
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))

      redirect_id ->
        persona = Repo.get!(Persona, redirect_id)
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
    end
  end

  def redirect(conn, %{"id" => id, "target_id" => target_id}, user) do
    id = String.to_integer(id)
    target_id = String.to_integer(target_id)

    persona_ids =
      from(m in Manifestation,
        where: m.user_id == ^user.id,
        select: m.persona_id
      )
      |> Repo.all()

    if id in persona_ids && target_id in persona_ids do
      from(p in Persona, where: p.id == ^id)
      |> Repo.update_all(set: [redirect_id: target_id])

      Search.Persona.delete_index(id)

      conn
      |> put_flash(:info, "Persona redirected successfully.")
      |> redirect(to: user_frontend_path(conn, :my_profile))
    else
      render(conn, "not_allowed.html")
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

      Search.Persona.update_index(id)

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

    persona_ids =
      from(m in Manifestation,
        where: m.user_id == ^user.id,
        select: m.persona_id
      )
      |> Repo.all()

    if id in persona_ids and delegate_id in persona_ids do
      case Repo.get_by(Delegation,
             persona_id: id,
             delegate_id: delegate_id
           ) do
        nil ->
          %Delegation{persona_id: id, delegate_id: delegate_id}
          |> Repo.insert()

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
    |> Pan.Mailer.deliver_now!

    render(conn, "email_sent.html")
  end

  def grant_access(conn, %{"id" => id, "token" => token}, _user) do
    user_id = String.to_integer(id)

    case PanWeb.Auth.grant_access_by_token(conn, token) do
      {:ok, persona_id} ->
        case Repo.get_by(Manifestation,
               user_id: user_id,
               persona_id: persona_id
             ) do
          nil ->
            %Manifestation{user_id: user_id, persona_id: persona_id}
            |> Repo.insert()

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
      |> PanWeb.Persona.claiming_changeset(%{user_id: user.id, email: user.email})
      |> Repo.update()

      %Manifestation{user_id: user.id, persona_id: persona.id}
      |> Repo.insert()

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
    |> PanWeb.Persona.claiming_changeset(%{user_id: nil, email: nil})
    |> Repo.update()

    conn
    |> put_flash(:info, "Persona disconnected successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end
