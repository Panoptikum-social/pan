defmodule Pan.Search do
  require Logger
  alias Pan.Episode
  alias Pan.Category
  alias Pan.User
  alias Pan.Persona
  alias Pan.Podcast

  alias Pan.Repo
  import Ecto.Query, only: [from: 2]

  def push(hours) do
    hours_ago = Timex.now()
                |> Timex.shift(hours: -1 * hours)

    Logger.info("=== Indexing categories (since #{inspect hours_ago}) ===")
    from(c in Category, where: c.updated_at >= ^hours_ago,
                        select: c.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Category.update_search_index(id)
       end)

    Logger.info("=== Indexing users ===")
    from(u in User, where: u.updated_at >= ^hours_ago,
                    select: u.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         User.update_search_index(id)
       end)

    Logger.info("=== Indexing personas ===")
    from(p in Persona, where: p.updated_at >= ^hours_ago,
                       select: p.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Persona.update_search_index(id)
       end)

    Logger.info("=== Indexing podcasts ===")
    from(p in Podcast, where: p.updated_at >= ^hours_ago,
                       select: p.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Podcast.update_search_index(id)
       end)

    Logger.info("=== Indexing episodes ===")
    from(e in Episode, where: e.updated_at >= ^hours_ago,
                       select: e.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Episode.update_search_index(id)
       end)

    Logger.info("=== Indexing finished ===")
  end


  def push_all() do
    Logger.info("=== Indexing categories (all) ===")
    from(c in Category, select: c.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Category.update_search_index(id)
       end)

    Logger.info("=== Indexing users ===")
    from(u in User, select: u.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         User.update_search_index(id)
       end)

    Logger.info("=== Indexing personas ===")
    from(p in Persona, select: p.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Persona.update_search_index(id)
       end)

    Logger.info("=== Indexing podcasts ===")
    from(p in Podcast, select: p.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Podcast.update_search_index(id)
       end)

    Logger.info("=== Indexing episodes ===")
    from(e in Episode, select: e.id)
    |> Repo.all()
    |> Enum.map(fn(id) ->
         Episode.update_search_index(id)
       end)

    Logger.info("=== Indexing finished ===")
  end
end