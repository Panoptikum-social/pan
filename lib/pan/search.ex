defmodule Pan.Search do
  require Logger
  alias PanWeb.Episode
  alias PanWeb.Category
  alias PanWeb.User
  alias PanWeb.Persona
  alias PanWeb.Podcast

  alias Pan.Repo
  import Ecto.Query, only: [from: 2]

  def push(hours) do
    hours_ago = Timex.now()
                |> Timex.shift(hours: -1 * hours)

    Logger.info("=== Indexing categories (since #{inspect hours_ago}) ===")
    categories_query = from(c in Category,
                 where: c.updated_at >= ^hours_ago,
                 select: c.id)
    categories_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Category.update_search_index(id)
       end)

    Logger.info("=== Indexing users ===")
    users_query = from(u in User,
                       where: u.updated_at >= ^hours_ago,
                       select: u.id)
    users_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         User.update_search_index(id)
       end)

    Logger.info("=== Indexing personas ===")
    personas_query = from(p in Persona,
                          where: p.updated_at >= ^hours_ago,
                          select: p.id)
    personas_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Persona.update_search_index(id)
       end)

    Logger.info("=== Indexing podcasts ===")
    podcasts_query = from(p in Podcast,
                          where: p.updated_at >= ^hours_ago,
                          select: p.id)
    podcasts_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Podcast.update_search_index(id)
       end)

    Logger.info("=== Indexing episodes ===")
    episodes_query = from(e in Episode,
                          where: e.updated_at >= ^hours_ago,
                          select: e.id)
    episodes_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Episode.update_search_index(id)
       end)

    Logger.info("=== Indexing finished ===")
  end


  def push_all() do
    Logger.info("=== Indexing categories (all) ===")
    categories_query = from(c in Category, select: c.id)
    categories_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Category.update_search_index(id)
       end)

    Logger.info("=== Indexing users ===")
    users_query = from(u in User, select: u.id)
    users_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         User.update_search_index(id)
       end)

    Logger.info("=== Indexing personas ===")
    personas_query = from(p in Persona, select: p.id)
    personas_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Persona.update_search_index(id)
       end)

    Logger.info("=== Indexing podcasts ===")
    podcasts_query = from(p in Podcast, select: p.id)
    podcasts_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Podcast.update_search_index(id)
       end)

    Logger.info("=== Indexing episodes ===")
    episodes_query = from(e in Episode, select: e.id)
    episodes_query
    |> Repo.all()
    |> Enum.each(fn(id) ->
         Episode.update_search_index(id)
       end)

    Logger.info("=== Indexing finished ===")
  end
end
