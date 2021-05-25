defmodule PanWeb.EpisodeController do
  use PanWeb, :controller
  alias PanWeb.Episode
  alias Pan.Search
  require Logger

  plug(:scrub_params, "episode" when action in [:create, :update])

  def remove_duplicates(conn, _params) do
    duplicate_episodes =
      from(e in Episode,
        group_by: [e.podcast_id, e.guid],
        having: count(e.guid) > 1,
        select: [e.podcast_id, e.guid]
      )
      |> Repo.all()

    for [podcast_id, guid] <- duplicate_episodes do
      episode =
        from(e in Episode,
          where: e.podcast_id == ^podcast_id and e.guid == ^guid,
          limit: 1
        )
        |> Repo.all()
        |> List.first()

      Repo.delete(episode)
      Search.Episode.delete_index(episode.id)
    end

    render(conn, "duplicates.html", duplicate_episodes: duplicate_episodes)
  end

  def remove_javascript_from_shownotes(conn, _params) do
    episodes =
      from(e in Episode,
        where: like(e.shownotes, "%(function%"),
        limit: 1000,
        order_by: e.id
      )
      |> Repo.all()

    for episode <- episodes do
      sanitized_shownotes =
        episode.shownotes
        |> String.replace(~r/\$\('.*}\);/isU, "")
        |> String.replace(~r/\(function.*\(\);/isU, "")
        |> String.replace(~r/\(function.*\)\);/isU, "")
        |> String.replace(~r/\(function.*\('altnerd'\);/isU, "")
        |> String.replace(~r/\(function.*smcx-sdk"\);/isU, "")
        |> String.replace(~r/jquery\(.*\(jQuery\);/isU, "")
        |> String.replace(~r/jquery\(.*}\)}\);/isU, "")
        |> String.replace(~r/jQuery\(.*} ?\);/isU, "")
        |> String.replace(~r/window.podcastData.*}/is, "")
        |> String.replace(~r/window.gie.*\)}\);/isU, "")
        |> String.replace(~r/__ATA.cmd.push.*}\);/is, "")
        |> String.replace(~r/if\(typeof\(jQuery.*}\);/is, "")
        |> String.replace(~r/<span>Advertisements.* 'important'\);/is, "")
        |> String.replace(~r/<span>Anuncios.* 'important'\);/is, "")
        |> String.replace(~r/\(document.*"js";/isU, "")

      Episode.changeset(episode, %{shownotes: sanitized_shownotes, link: fallback_link(episode)})
      |> Repo.update()
    end

    Logger.info("=== Sanitized #{length(episodes)} episodes ... ===")
    render(conn, "done.html")
  end

  defp fallback_link(episode) do
    episode.link || episode_frontend_path(PanWeb.Endpoint, :show, episode)
  end
end
