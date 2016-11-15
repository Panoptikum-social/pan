defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category

  def new(conn, %{"search" => search}) do
    searchstring = search["searchstring"]

    categories = Repo.all(from c in Category,
                          where: ilike(c.title, ^"%#{searchstring}%"))

    podcasts = Repo.all(from p in Podcast,
                        select: %{id: p.id,
                                  title: p.title,
                                  type: "Title",
                                  match: p.title},
                        where: ilike(p.title, ^"%#{searchstring}%"))
            ++ Repo.all(from p in Podcast,
                        select: %{id: p.id,
                                  title: p.title,
                                  type: "Description",
                                  match: p.description},
                        where: ilike(p.description, ^"%#{searchstring}%"))
            ++ Repo.all(from p in Podcast,
                        select: %{id: p.id,
                                  title: p.title,
                                  type: "Summary",
                                  match: p.summary},
                        where: ilike(p.summary, ^"%#{searchstring}%"))
            ++ Repo.all(from p in Podcast,
                        select: %{id: p.id,
                                  title: p.title,
                                  type: "Author",
                                  match: p.author},
                        where: ilike(p.author, ^"%#{searchstring}%"))

    episodes = Repo.all(from e in Episode,
                        select: %{id: e.id,
                                  title: e.title,
                                  type: "Title",
                                  match: e.title},
                        where: ilike(e.title, ^"%#{searchstring}%"))
            ++ Repo.all(from e in Episode,
                        select: %{id: e.id,
                                  title: e.title,
                                  type: "Subtitle",
                                  match: e.subtitle},
                        where: ilike(e.subtitle, ^"%#{searchstring}%"))
            ++ Repo.all(from e in Episode,
                        select: %{id: e.id,
                                  title: e.title,
                                  type: "Description",
                                  match: e.description},
                        where: ilike(e.description, ^"%#{searchstring}%"))
            ++ Repo.all(from e in Episode,
                        select: %{id: e.id,
                                  title: e.title,
                                  type: "Summary",
                                  match: e.summary},
                        where: ilike(e.summary, ^"%#{searchstring}%"))
            ++ Repo.all(from e in Episode,
                        select: %{id: e.id,
                                  title: e.title,
                                  type: "Author",
                                  match: e.author},
                        where: ilike(e.author, ^"%#{searchstring}%"))
            ++ Repo.all(from e in Episode,
                        select: %{id: e.id,
                                  title: e.title,
                                  type: "Shownotes",
                                  match: e.shownotes},
                        where: ilike(e.shownotes, ^"%#{searchstring}%"))

    render(conn, "new.html", searchstring: searchstring,
                             categories: categories,
                             podcasts: podcasts,
                             episodes: episodes)
  end
end

