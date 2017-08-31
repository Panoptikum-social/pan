defmodule Pan.PersonaApiController do
  use Pan.Web, :controller
  alias Pan.Persona
  use JaSerializer

  def show(conn, %{"id" => id}) do
    persona = Repo.get(Persona, id)
              |> Repo.preload([:redirect, :delegates, :engagements])

    render conn, "show.json-api", data: persona, opts: [include: "rediect,delegates,engagements"]
  end
end
