defmodule Pan.Updater.Podcast do
  alias Pan.Repo
  alias Pan.Parser.Helpers, as: H
  alias Pan.Parser.{Download, Feed, Persistor}
  alias Pan.Updater.{RssFeed}
  alias PanWeb.{Endpoint, Podcast}
  require Logger


  def import_new_episodes(podcast, current_user \\ nil, forced \\ false, no_failure_count_increase \\ false) do
    Logger.info("\n\e[96m === #{podcast.id} ⬇ #{podcast.title} ===\e[0m")

    with {:ok, _podcast} <- set_next_update(podcast),
         {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, "go on"} <- Pan.Updater.Feed.needs_update(feed, podcast, forced),
         {:ok, feed_xml} <- Download.download(feed.self_link_url),
         {:ok, map} <- RssFeed.import_to_map(feed_xml, feed, podcast.id, forced),
         {:ok, _} <- Persistor.delta_import(map, podcast),
         {:ok, _} <- unpause_and_reset_failure_count(podcast) do
      notify_user(current_user, {:ok, "imported"}, podcast)
      {:ok, "Podcast #{podcast.id}: #{podcast.title} updated"}
    else
      {:redirect, redirect_target} ->
        Feed.update_with_redirect_target(podcast.id, H.to_255(redirect_target))
        import_new_episodes(podcast, current_user)

      {:error, message} ->
        unless no_failure_count_increase == :no_failure_count_increase, do: increase_failure_count(podcast)
        Logger.warn(message)
        notify_user(current_user, {:error, message}, podcast)
        {:error, message}

      {:done, "nothing to do"} ->
        {:ok, "Podcast #{podcast.id}: #{podcast.title}: nothing to do"}
    end
  end


  defp set_next_update(podcast) do
    next_update = Timex.shift(Timex.now(), hours: podcast.update_intervall + 1)

    Podcast.changeset(podcast, %{
      update_intervall: podcast.update_intervall + 1,
      next_update: next_update
    })
    |> Repo.update()
  end

  defp notify_user(nil, _, _), do: nil

  defp notify_user(current_user, {status, message}, podcast) do
    notification = build_notification(podcast, {status, message}, current_user)
    Endpoint.broadcast("mailboxes:#{current_user.id}", "notification", notification)
  end

  defp build_notification(podcast, {:ok, _}, current_user) do
    %{
      content:
        "<i class='fa fa-refresh'></i> #{podcast.id} " <>
          "<i class='fa fa-podcast'></i> #{podcast.title}",
      type: "success",
      user_name: current_user && current_user.name
    }
  end

  defp build_notification(podcast, {:error, message}, current_user) do
    %{
      content:
        "Error: #{message} | <i class='fa fa-refresh'></i> #{podcast.id} " <>
          "<i class='fa fa-podcast'></i> #{podcast.title}",
      type: "danger",
      user_name: current_user && current_user.name
    }
  end

  def unpause_and_reset_failure_count(podcast) do
    PanWeb.Podcast.changeset(podcast, %{update_paused: false,
                                        retired: false,
                                        failure_count: 0})
    |> Repo.update(force: true)
  end

  defp increase_failure_count(podcast) do
    Podcast.changeset(podcast, %{failure_count: (podcast.failure_count || 0) + 1})
    |> Repo.update(force: true)

    if podcast.failure_count == 9 do
      Podcast.changeset(podcast, %{retired: true})
      |> Repo.update(force: true)
    end
  end
end
