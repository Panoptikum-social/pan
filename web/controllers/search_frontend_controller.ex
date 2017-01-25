defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category

  def new(conn, params) do
    sqlfrag = "%" <> params["search"]["searchstring"] <> "%"

    page = if params["page"] != nil, do: String.to_integer(params["page"]), else: 1

    categories = Repo.all(from c in Category, where: ilike(c.title, ^sqlfrag))

    podcasts = from(p in Podcast, where: ilike(p.title,       ^sqlfrag) or
                                         ilike(p.description, ^sqlfrag) or
                                         ilike(p.summary,     ^sqlfrag) or
                                         ilike(p.author,      ^sqlfrag))
               |> Repo.paginate(page: page, page_size: 10)

    episodes = from(e in Episode, where: ilike(e.title,       ^sqlfrag) or
                                         ilike(e.subtitle,    ^sqlfrag) or
                                         ilike(e.description, ^sqlfrag) or
                                         ilike(e.summary,     ^sqlfrag) or
                                         ilike(e.author,      ^sqlfrag) or
                                         ilike(e.shownotes,   ^sqlfrag),
                                  preload: :podcast)
               |> Repo.paginate(page: page, page_size: 10)

    render(conn, "new.html", searchstring: params["search"]["searchstring"],
                             categories: categories,
                             podcasts: podcasts,
                             episodes: episodes)
  end
end

