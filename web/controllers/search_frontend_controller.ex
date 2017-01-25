defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category

  def new(conn, params) do
    sqlfrag = params["search"]["searchstring"]
              |> String.replace(" ", " & ")

    page = if params["page"] != nil, do: String.to_integer(params["page"]), else: 1

    categories = Repo.all(from c in Category, where: ilike(c.title, ^sqlfrag))
    podcasts = from(p in Podcast, where: fragment("to_tsvector('german', title || ' ' || summary || ' ' || description || ' ' || author) @@ to_tsquery(?)", ^sqlfrag))
               |> Repo.paginate(page: page, page_size: 10)

    episodes = from(e in Episode, where: fragment("to_tsvector('german', title || ' ' || summary || ' ' || description || ' ' || author || ' ' || shownotes || ' ' || subtitle) @@ to_tsquery(?)", ^sqlfrag),
                                  preload: :podcast)
               |> Repo.paginate(page: page, page_size: 10)

    render(conn, "new.html", searchstring: params["search"]["searchstring"],
                             categories: categories,
                             podcasts: podcasts,
                             episodes: episodes)
  end
end