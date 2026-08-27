defmodule Pan.Updater.Podcast do
  alias Pan.Repo
  alias Pan.Parser.Helpers, as: H
  alias Pan.Parser.{Download, Feed, Persistor}
  alias Pan.Updater.RssFeed
  alias PanWeb.Podcast
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]
  require Logger

  # update_intervall backs off by one hour every time a scheduled update
  # comes up empty (see set_next_update/2 below); cap it so a podcast that's
  # gone quiet for a long time still gets checked at least weekly instead of
  # drifting towards an ever-growing wait.
  @max_update_intervall_hours 24 * 7

  def max_update_intervall_hours, do: @max_update_intervall_hours

  # Feed.update_with_redirect_target/2 already refuses a redirect that leads
  # back to a URL this feed has held before, but that only catches actual
  # cycles: a server that keeps redirecting to a new, never-before-seen URL
  # (e.g. a cache-busting query string) would otherwise be followed forever.
  # This caps the number of hops we'll chase per update, independent of that
  # cycle check.
  @max_redirects 5

  def import_new_episodes(
        podcast,
        forced \\ false,
        no_failure_count_increase \\ false,
        do_not_increase_update_interval \\ false
      ) do
    import_new_episodes(
      podcast,
      forced,
      no_failure_count_increase,
      do_not_increase_update_interval,
      0
    )
  end

  defp import_new_episodes(
         podcast,
         forced,
         no_failure_count_increase,
         do_not_increase_update_interval,
         redirect_count
       ) do
    Logger.info("=== #{podcast.id} ⬇ #{podcast.title} ===")

    with {:ok, _podcast} <- set_next_update(podcast, do_not_increase_update_interval),
         {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, "go on"} <- Pan.Updater.Feed.needs_update(feed, podcast, forced),
         {:ok, feed_xml} <- Download.download(feed.self_link_url, feed.id),
         {:ok, map} <- RssFeed.import_to_map(feed_xml, feed, podcast.id, forced),
         {:ok, _} <- Persistor.delta_import(map, podcast),
         {:ok, _} <- unpause_and_reset_failure_count(podcast) do
      notify({:ok, "imported"}, podcast)
      {:ok, "Podcast #{podcast.id}: #{podcast.title} updated"}
    else
      {:redirect, redirect_target} ->
        if redirect_count >= @max_redirects do
          handle_message(podcast, "too many redirects", no_failure_count_increase)
        else
          case Feed.update_with_redirect_target(podcast.id, H.to_255(redirect_target)) do
            {:ok, _} ->
              Logger.info("=== #{podcast.id} redirect -> #{redirect_target} ===")

              import_new_episodes(
                podcast,
                forced,
                no_failure_count_increase,
                do_not_increase_update_interval,
                redirect_count + 1
              )

            {:error, message} ->
              handle_message(podcast, message, no_failure_count_increase)
          end
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

    Logger.warning(message)

    message =
      case message do
        %HTTPoison.Error{reason: reason} -> inspect(reason)
        _ -> message
      end

    notify({:error, message}, podcast)
    {:error, message}
  end

  defp set_next_update(podcast, do_not_increase_update_interval) do
    if do_not_increase_update_interval == :do_not_increase_update_interval do
      {:ok, "nothing to do"}
    else
      update_intervall = min(podcast.update_intervall + 1, @max_update_intervall_hours)
      next_update = time_shift(now(), hours: update_intervall)

      Podcast.changeset(podcast, %{
        update_intervall: update_intervall,
        next_update: next_update
      })
      |> Repo.update()
    end
  end

  defp notify({status, message}, podcast) do
    # For monitoring purposes, Notifications can be enabled here by uncommenting the next line:
    _message = build_notification(podcast, {status, message})
    # Phoenix.PubSub.broadcast(:pan_pubsub, "admin", message)
  end

  defp build_notification(podcast, {:ok, _}),
    do: %{content: "Podcast #{podcast.id}: #{podcast.title}"}

  defp build_notification(
         podcast,
         {:error, %HTTPoison.Error{reason: {:tls_alert, {error, message}}}}
       ) do
    %{content: "TLS Error: #{error} / #{message} | Podcast #{podcast.id}: #{podcast.title}"}
  end

  defp build_notification(
         podcast,
         {:error, %HTTPoison.Error{reason: :enetunreach, id: nil}}
       ) do
    %{content: "Network Error: not reached | Podcast #{podcast.id}: #{podcast.title}"}
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
