defmodule PanWeb.Api.DelegationController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Delegation, Manifestation, Persona}
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, user) do
    persona_ids =
      from(m in Manifestation,
        where: m.user_id == ^user.id,
        select: m.persona_id
      )
      |> Repo.all()

    delegation =
      Repo.get(Delegation, id)
      |> Repo.preload([:persona, :delegate])

    if delegation do
      if delegation.persona_id in persona_ids and delegation.delegate_id in persona_ids do
        render(conn, "show.json-api",
          data: delegation,
          opts: [include: "persona,delegate"]
        )
      else
        Helpers.send_401(conn, "You are not a manifestation of both of this personas.")
      end
    else
      Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"persona_id" => id, "delegate_id" => delegate_id}, user) do
    id = String.to_integer(id)
    delegate_id = String.to_integer(delegate_id)

    with %PanWeb.Persona{} <- Repo.get(Persona, id),
         %PanWeb.Persona{} <- Repo.get(Persona, delegate_id),
         true <- delegate_id != id do
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
            {:ok, delegation} =
              %Delegation{persona_id: id, delegate_id: delegate_id}
              |> Repo.insert()

            delegation =
              delegation
              |> Repo.preload([:persona, :delegate])
              |> mark_if_deleted()

            render(conn, "show.json-api",
              data: delegation,
              opts: [include: "persona,delegate"]
            )

          delegation ->
            delegation =
              Repo.delete!(delegation)
              |> Repo.preload([:persona, :delegate])
              |> mark_if_deleted()

            render(conn, "show.json-api",
              data: delegation,
              opts: [include: "persona,delegate"]
            )
        end
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
          "delegations can only happen between different personas"
        )
    end
  end
end
