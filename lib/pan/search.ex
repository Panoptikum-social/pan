defmodule Pan.Search do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.{Category, Episode, Persona, Podcast}
  require Logger
  alias HTTPoison.Response

  def push_missing do
    category_ids =
      from(c in Category, where: not c.full_text, select: c.id)
      |> Repo.all()

    manticore_data =
      from(c in Category, where: c.id in ^category_ids)
      |> Repo.all()
      |> Enum.map(&%{insert: %{index: "categories", id: &1.id, doc: %{title: &1.title}}})
      |> Enum.map(&Jason.encode!(&1))
      |> Enum.join("\n")

    {:ok, %Response{status_code: response_code, body: response_body}} =
      HTTPoison.post("http://localhost:9308/bulk", manticore_data, [
        {"Content-Type", "application/x-ndjson"}
      ])

    IO.inspect(response_body)

    if response_code == 200 do
      from(c in Category, where: c.id in ^category_ids)
      |> Repo.update_all(set: [full_text: true])
    end

    Logger.info("=== Indexed #{length(category_ids)} categories ===")

    #  persona_ids =
    #   from(c in Persona,
    #     where: not c.full_text,
    #     limit: 1000,
    #     select: c.id
    #   )
    #   |> Repo.all()

    # for id <- persona_ids, do: Persona.update_search_index(id)

    # from(c in Persona, where: c.id in ^persona_ids)
    # |> Repo.update_all(set: [full_text: true])

    # Logger.info("=== Indexed #{length(persona_ids)} personas ===")

    # podcast_ids =
    #   from(c in Podcast,
    #     where: not c.full_text,
    #     limit: 100,
    #     select: c.id
    #   )
    #   |> Repo.all()

    # for id <- podcast_ids, do: Podcast.update_search_index(id)

    # from(c in Podcast, where: c.id in ^podcast_ids)
    # |> Repo.update_all(set: [full_text: true])

    # Logger.info("=== Indexed #{length(podcast_ids)} podcasts ===")

    # episode_ids =
    #   from(c in Episode,
    #     where: not c.full_text,
    #     limit: 1000,
    #     select: c.id
    #   )
    #   |> Repo.all()

    # for id <- episode_ids, do: Episode.update_search_index(id)

    # from(c in Episode, where: c.id in ^episode_ids)
    # |> Repo.update_all(set: [full_text: true])

    # Logger.info("=== Indexed #{length(episode_ids)} episodes ===")
    # Logger.info("=== Indexing finished ===")
  end

  def reset_all do
    IO.puts("resetting all categories")
    Repo.update_all(Category, set: [full_text: false])
    reset_podcasts()
    reset_personas()
    reset_episodes()
  end

  defp reset_podcasts do
    IO.puts("resetting up to 10_000 podcasts")

    podcast_ids =
      from(p in Podcast,
        where: p.full_text == true,
        select: p.id,
        limit: 10_000
      )
      |> Repo.all()

    from(p in Podcast, where: p.id in ^podcast_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(podcast_ids) > 0, do: reset_podcasts()
  end

  defp reset_personas do
    IO.puts("resetting up to 10_000 personas")

    persona_ids =
      from(p in Persona,
        where: p.full_text == true,
        select: p.id,
        limit: 10_000
      )
      |> Repo.all()

    from(p in Persona, where: p.id in ^persona_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(persona_ids) > 0, do: reset_personas()
  end

  defp reset_episodes do
    IO.puts("resetting up to 10_000 episodes")

    episode_ids =
      from(e in Episode,
        where: e.full_text == true,
        select: e.id,
        limit: 10_000
      )
      |> Repo.all()

    from(e in Episode, where: e.id in ^episode_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(episode_ids) > 0, do: reset_episodes()
  end
end
