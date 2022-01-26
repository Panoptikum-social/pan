defmodule Pan.Updater.Podcast do
  alias Pan.Repo
  alias Pan.Parser.Helpers, as: H
  alias Pan.Parser.{Download, Feed, Persistor}
  alias Pan.Updater.RssFeed
  alias PanWeb.Podcast
  import Pan.Parser.MyDateTime, only: [now: 0]
  require Logger

  def import_new_episodes(podcast, forced \\ false, no_failure_count_increase \\ false) do
    Logger.info("=== #{podcast.id} ⬇ #{podcast.title} ===")

    with {:ok, _podcast} <- set_next_update(podcast),
         {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, "go on"} <- Pan.Updater.Feed.needs_update(feed, podcast, forced),
         {:ok, feed_xml} <- Download.download(feed.self_link_url, nil, feed.id),
         {:ok, map} <- RssFeed.import_to_map(feed_xml, feed, podcast.id, forced),
         {:ok, _} <- Persistor.delta_import(map, podcast),
         {:ok, _} <- unpause_and_reset_failure_count(podcast) do
      notify({:ok, "imported"}, podcast)
      {:ok, "Podcast #{podcast.id}: #{podcast.title} updated"}
    else
      {:redirect, redirect_target} ->
        case Feed.update_with_redirect_target(podcast.id, H.to_255(redirect_target)) do
          {:ok, _} ->
            import_new_episodes(podcast, forced, no_failure_count_increase)

          {:error, message} ->
            handle_message(podcast, message, no_failure_count_increase)
        end

      {:error, message} ->
        handle_message(podcast, message, no_failure_count_increase)

      {:done, "nothing to do"} ->
        {:ok, "Podcast #{podcast.id}: #{podcast.title}: nothing to do"}
    end
  end

  defp handle_message(podcast, message, no_failure_count_increase) do
    unless no_failure_count_increase == :no_failure_count_increase do
      increase_failure_count_and_persist_error(podcast, message)
    end

    Logger.warn(message)
    notify({:error, message}, podcast)
    {:error, message}
  end

  defp set_next_update(podcast) do
    next_update = Timex.shift(now(), hours: podcast.update_intervall + 1)

    Podcast.changeset(podcast, %{
      update_intervall: podcast.update_intervall + 1,
      next_update: next_update
    })
    |> Repo.update()
  end

  defp notify({status, message}, podcast) do
    Phoenix.PubSub.broadcast(:pan_pubsub, "admin", build_notification(podcast, {status, message}))
  end

  defp build_notification(podcast, {:ok, _}),
    do: %{content: "Podcast #{podcast.id}: #{podcast.title}"}

  defp build_notification(
         podcast,
         {:error, %HTTPoison.Error{reason: {:tls_alert, {error, message}}}}
       ) do
    %{content: "TLS Error: #{error} / #{message} | Podcast #{podcast.id}: #{podcast.title}"}
  end

  defp build_notification(podcast, {:error, message}) do
    %{content: "Error: #{message} | Podcast #{podcast.id}: #{podcast.title}"}
  end

  def unpause_and_reset_failure_count(podcast) do
    Podcast.changeset(podcast, %{update_paused: false, retired: false, failure_count: 0})
    |> Repo.update(force: true)
  end

  defp increase_failure_count_and_persist_error(podcast, message) do
    Podcast.changeset(podcast, %{
      failure_count: (podcast.failure_count || 0) + 1,
      last_error_message: message,
      last_error_occured: now()
    })
    |> Repo.update(force: true)

    if podcast.failure_count == 9 do
      Podcast.changeset(podcast, %{retired: true})
      |> Repo.update(force: true)
    end
  end
end
