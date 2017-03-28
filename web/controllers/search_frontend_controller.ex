defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category
  alias Pan.User
  alias Pan.Persona

  def new(conn, params) do
    frag = params["search"]["searchstring"]
           |> String.split(" ")
           |> Enum.map(fn(word) -> "%" <> word <> "%" end)

    page = if params["page"] != nil, do: String.to_integer(params["page"]), else: 1

    users = Repo.all(from u in User, where: fragment("(? ILIKE ALL (?))", u.name, ^frag) or
                                            fragment("(? ILIKE ALL (?))", u.username, ^frag))

    personas = Repo.all(from p in Persona, where: fragment("(? ILIKE ALL (?))", p.pid, ^frag) or
                                                  fragment("(? ILIKE ALL (?))", p.name, ^frag) or
                                                  fragment("(? ILIKE ALL (?))", p.uri, ^frag))

    categories = Repo.all(from c in Category, where: fragment("(? ILIKE ALL (?))", c.title, ^frag))

    podcasts = from(p in Podcast, where: fragment("(? ILIKE ALL (?))", p.title, ^frag) or
                                         fragment("(? ILIKE ALL (?))", p.description, ^frag) or
                                         fragment("(? ILIKE ALL (?))", p.summary, ^frag))
               |> Repo.paginate(page: page, page_size: 10)

    episodes = from(e in Episode, where: fragment("(? ILIKE ALL (?))", e.title, ^frag) or
                                         fragment("(? ILIKE ALL (?))", e.subtitle, ^frag) or
                                         fragment("(? ILIKE ALL (?))", e.description, ^frag) or
                                         fragment("(? ILIKE ALL (?))", e.summary, ^frag) or
                                         fragment("(? ILIKE ALL (?))", e.shownotes, ^frag),
                                  preload: :podcast)
               |> Repo.paginate(page: page, page_size: 10)

    render(conn, "new.html", searchstring: params["search"]["searchstring"],
                             users: users,
                             personas: personas,
                             categories: categories,
                             podcasts: podcasts,
                             episodes: episodes)
  end
end