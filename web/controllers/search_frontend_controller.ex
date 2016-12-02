defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category

  def new(conn, params) do
    sqlfrag = "%" <> params["search"]["searchstring"] <> "%"

    categories = Repo.all(from c in Category,
                          where: ilike(c.title, ^sqlfrag))

    query = from p in Podcast,
            where: ilike(p.title,       ^sqlfrag) or
                   ilike(p.description, ^sqlfrag) or
                   ilike(p.summary,     ^sqlfrag) or
                   ilike(p.author,      ^sqlfrag)
    podcasts = Ecto.Queryable.to_query(query)
               |> Repo.paginate(params)


    query = from e in Episode,
            where: ilike(e.title,       ^sqlfrag) or
                   ilike(e.subtitle,    ^sqlfrag) or
                   ilike(e.description, ^sqlfrag) or
                   ilike(e.summary,     ^sqlfrag) or
                   ilike(e.author,      ^sqlfrag) or
                   ilike(e.shownotes,   ^sqlfrag)
    episodes = Ecto.Queryable.to_query(query)
               |> Repo.paginate(params)

    render(conn, "new.html", searchstring: params["search"]["searchstring"],
                             categories: categories,
                             podcasts: podcasts,
                             episodes: episodes)
  end
end