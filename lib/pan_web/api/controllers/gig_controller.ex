defmodule PanWeb.Api.GigController do
  use PanWeb, :controller
  use JaSerializer
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]
  alias PanWeb.{Api.Helpers, Episode, Gig, Persona}

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, _user) do
    gig =
      Repo.get(Gig, id)
      |> Repo.preload([:persona, :episode])

    if gig do
      render(conn, "show.json-api",
        data: gig,
        opts: [include: "episode,persona"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"episode_id" => episode_id, "persona_id" => persona_id}, user) do
    with %PanWeb.Episode{} <- Repo.get(Episode, episode_id),
         %PanWeb.Persona{} <- Repo.get(Persona, persona_id) do
      case Gig.proclaim(String.to_integer(episode_id), String.to_integer(persona_id), user.id) do
        {:ok, gig} ->
          gig =
            gig
            |> Repo.preload([:episode, :persona])
            |> mark_if_deleted()

          render(conn, "show.json-api",
            data: gig,
            opts: [include: "episode,persona"]
          )

        {:error, "not your persona"} ->
          Helpers.send_401(conn, "not your persona")
      end
    else
      nil -> Helpers.send_404(conn)
    end
  end
end
