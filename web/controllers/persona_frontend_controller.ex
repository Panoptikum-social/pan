defmodule Pan.PersonaFrontendController do
  use Pan.Web, :controller
  alias Pan.Persona
  alias Pan.Message
  alias Pan.Gig


  def index(conn, _params) do
    personas = Repo.all(from p in Pan.Persona, order_by: :name)
    render(conn, "index.html", personas: personas)
  end


  def show(conn, params) do
    id = String.to_integer(params["id"])

    persona = Repo.get!(Persona, id)
              |> Repo.preload(gigs: from(g in Gig, order_by: [desc: :publishing_date],
                                                   preload: :episode))
              |> Repo.preload(engagements: :podcast)

    messages = from(m in Message, where: m.persona_id == ^id,
                                  order_by: [desc: :inserted_at],
                                  preload: [:persona])
               |> Repo.paginate(params)

    render(conn, "show.html", persona: persona, messages: messages)
  end


  def persona(conn, params) do
    pid = params["pid"]

    persona = Repo.one(from p in Pan.Persona, where: p.pid == ^pid)
              |> Repo.preload(gigs: from(g in Gig, order_by: [desc: :publishing_date],
                                                   preload: :episode))
              |> Repo.preload(engagements: :podcast)

    messages = from(m in Message, where: m.persona_id == ^persona.id,
                                  order_by: [desc: :inserted_at],
                                  preload: [:persona])
               |> Repo.paginate(params)

    render(conn, "show.html", persona: persona, messages: messages)
  end
end