defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller

  def new(conn, %{"search" => search}) do
    searchstring = search["searchstring"]

    categories = Repo.all(from category in Pan.Category,
                          where: like(category.title, ^"%#{searchstring}%"))

    podcasts = Repo.all(from podcast in Pan.Podcast,
                        select: %{id: podcast.id,
                                  title: podcast.title,
                                  type: "Title",
                                  match: podcast.title},
                        where: like(podcast.title, ^"%#{searchstring}%"))
            ++ Repo.all(from podcast in Pan.Podcast,
                        select: %{id: podcast.id,
                                  title: podcast.title,
                                  type: "Description",
                                  match: podcast.description},
                        where: like(podcast.description, ^"%#{searchstring}%"))
            ++ Repo.all(from podcast in Pan.Podcast,
                        select: %{id: podcast.id,
                                  title: podcast.title,
                                  type: "Summary",
                                  match: podcast.summary},
                        where: like(podcast.summary, ^"%#{searchstring}%"))
            ++ Repo.all(from podcast in Pan.Podcast,
                        select: %{id: podcast.id,
                                  title: podcast.title,
                                  type: "Author",
                                  match: podcast.author},
                        where: like(podcast.author, ^"%#{searchstring}%"))

    episodes = Repo.all(from episode in Pan.Episode,
                        select: %{id: episode.id,
                                  title: episode.title,
                                  type: "Title",
                                  match: episode.title},
                        where: like(episode.title, ^"%#{searchstring}%"))
            ++ Repo.all(from episode in Pan.Episode,
                        select: %{id: episode.id,
                                  title: episode.title,
                                  type: "Subtitle",
                                  match: episode.subtitle},
                        where: like(episode.subtitle, ^"%#{searchstring}%"))
            ++ Repo.all(from episode in Pan.Episode,
                        select: %{id: episode.id,
                                  title: episode.title,
                                  type: "Description",
                                  match: episode.description},
                        where: like(episode.description, ^"%#{searchstring}%"))
            ++ Repo.all(from episode in Pan.Episode,
                        select: %{id: episode.id,
                                  title: episode.title,
                                  type: "Summary",
                                  match: episode.summary},
                        where: like(episode.summary, ^"%#{searchstring}%"))
            ++ Repo.all(from episode in Pan.Episode,
                        select: %{id: episode.id,
                                  title: episode.title,
                                  type: "Author",
                                  match: episode.author},
                        where: like(episode.author, ^"%#{searchstring}%"))
            ++ Repo.all(from episode in Pan.Episode,
                        select: %{id: episode.id,
                                  title: episode.title,
                                  type: "Shownotes",
                                  match: episode.shownotes},
                        where: like(episode.shownotes, ^"%#{searchstring}%"))

    render(conn, "new.html", searchstring: searchstring,
                             categories: categories,
                             podcasts: podcasts,
                             episodes: episodes)
  end
end

