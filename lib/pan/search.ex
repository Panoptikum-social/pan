defmodule Pan.Search do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.{Category, Episode, Persona, Podcast, User}
  require Logger

  def push_missing do
    category_ids =
      from(c in Category,
        where: not c.full_text,
        limit: 100,
        select: c.id
      )
      |> Repo.all()

    for id <- category_ids, do: Category.update_search_index(id)

    from(c in Category, where: c.id in ^category_ids)
    |> Repo.update_all(set: [full_text: true])

    Logger.info("=== Indexed #{length(category_ids)} categories ===")

    user_ids =
      from(c in User,
        where: not c.full_text,
        limit: 100,
        select: c.id
      )
      |> Repo.all()

    for id <- user_ids, do: User.update_search_index(id)

    from(c in User, where: c.id in ^user_ids)
    |> Repo.update_all(set: [full_text: true])

    Logger.info("=== Indexed #{length(user_ids)} users ===")

    persona_ids =
      from(c in Persona,
        where: not c.full_text,
        limit: 1000,
        select: c.id
      )
      |> Repo.all()

    for id <- persona_ids, do: Persona.update_search_index(id)

    from(c in Persona, where: c.id in ^persona_ids)
    |> Repo.update_all(set: [full_text: true])

    Logger.info("=== Indexed #{length(persona_ids)} personas ===")

    podcast_ids =
      from(c in Podcast,
        where: not c.full_text,
        limit: 100,
        select: c.id
      )
      |> Repo.all()

    for id <- podcast_ids, do: Podcast.update_search_index(id)

    from(c in Podcast, where: c.id in ^podcast_ids)
    |> Repo.update_all(set: [full_text: true])

    Logger.info("=== Indexed #{length(podcast_ids)} podcasts ===")

    episode_ids =
      from(c in Episode,
        where: not c.full_text,
        limit: 1000,
        select: c.id
      )
      |> Repo.all()

    for id <- episode_ids, do: Episode.update_search_index(id)

    from(c in Episode, where: c.id in ^episode_ids)
    |> Repo.update_all(set: [full_text: true])

    Logger.info("=== Indexed #{length(episode_ids)} episodes ===")
    Logger.info("=== Indexing finished ===")
  end

  def push_all() do
    Logger.info("=== Indexing categories (all) ===")
    categories_query = from(c in Category, select: c.id)

    categories_query
    |> Repo.all()
    |> Enum.each(fn id ->
      Category.update_search_index(id)
    end)

    Logger.info("=== Indexing users ===")
    users_query = from(u in User, select: u.id)

    users_query
    |> Repo.all()
    |> Enum.each(fn id ->
      User.update_search_index(id)
    end)

    Logger.info("=== Indexing personas ===")
    personas_query = from(p in Persona, select: p.id)

    personas_query
    |> Repo.all()
    |> Enum.each(fn id ->
      Persona.update_search_index(id)
    end)

    Logger.info("=== Indexing podcasts ===")
    podcasts_query = from(p in Podcast, select: p.id)

    podcasts_query
    |> Repo.all()
    |> Enum.each(fn id ->
      Podcast.update_search_index(id)
    end)

    Logger.info("=== Indexing episodes ===")
    episodes_query = from(e in Episode, select: e.id)

    episodes_query
    |> Repo.all()
    |> Enum.each(fn id ->
      Episode.update_search_index(id)
    end)

    Logger.info("=== Indexing finished ===")
  end
end
