defmodule PanWeb.Api.GigController do
  use Pan.Web, :controller
  alias PanWeb.Gig
  use JaSerializer
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]
  import PanWeb.Api.Helpers, only: [send_401: 2]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, _user) do
    gig = Repo.get(Gig, id)
          |> Repo.preload([:persona, :episode])

    render conn, "show.json-api", data: gig, opts: [include: "episode,persona"]
  end


  def toggle(conn, %{"episode_id" => episode_id, "persona_id" => persona_id}, user) do
    case Gig.proclaim(String.to_integer(episode_id), String.to_integer(persona_id), user.id) do
      {:ok, gig} ->
        gig = gig
              |> Repo.preload([:episode, :persona])
              |> mark_if_deleted()

        render conn, "show.json-api", data: gig,
                                      opts: [include: "episode,persona"]

      {:error, "not your persona"} ->
        send_401(conn, "not your persona")
    end
  end
end