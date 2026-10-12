defmodule Pan.Updater.Succession do
  @moduledoc """
  Tells a moved or renamed podcast from a different show behind its feed.

  Some publishers retire podcast A and redirect its feed (or announce a new
  one with `<itunes:new-feed-url>`) to their new podcast B, to win the
  listeners over; a feed can also be taken over, e.g. via a bought domain.
  Following such a redirect would fill A with B's episodes.

  Before a new feed URL is saved, the episode titles of the new feed are
  compared with A's episodes:

  - title unchanged: a move, followed as before (a short feed of a frequent
    publisher can consist of new episodes only);
  - title changed, at least 50 % of the episode titles known: a rename or
    move, followed as before;
  - title changed, at most 10 % known: a succession. A stays as it is, the
    new URL goes into the feed backlog once for an admin to decide;
  - in between, or fewer than 3 episodes to compare: not followed, an admin
    gets an email.

  A is not retired in either case, its own feed still works.
  """

  import Ecto.Query
  alias Pan.Parser.{Download, Helpers}
  alias Pan.Repo
  alias Pan.Updater.RssFeed
  alias PanWeb.{Episode, Feed, FeedBacklog, Podcast}
  import Pan.Parser.MyDateTime, only: [now: 0]
  require Logger

  defmodule ReviewNeeded do
    defexception [:message]
  end

  @min_episodes 3
  @move_share 0.5
  @succession_share 0.1

  @doc """
  `{decision, share}`, decision `:move`, `:succession` or `:review`, share the
  part of the new feed's distinct episode titles already known for `podcast`.
  """
  def classify(podcast, new_title, episode_titles) do
    titles = episode_titles |> Enum.reject(&is_nil/1) |> Enum.uniq()
    share = known_share(podcast.id, titles)
    {decide(title_changed?(podcast.title, new_title), length(titles), share), share}
  end

  defp title_changed?(_old_title, nil), do: false
  defp title_changed?(nil, _new_title), do: true
  defp title_changed?(old_title, new_title), do: normalize(old_title) != normalize(new_title)

  defp normalize(title), do: title |> String.trim() |> String.downcase()

  defp known_share(_podcast_id, []), do: 0.0

  defp known_share(podcast_id, titles) do
    known =
      from(e in Episode,
        where: e.podcast_id == ^podcast_id and e.title in ^titles,
        select: count(e.title, :distinct)
      )
      |> Repo.one()

    known / length(titles)
  end

  defp decide(false, _count, _share), do: :move
  defp decide(true, count, _share) when count < @min_episodes, do: :review
  defp decide(true, _count, share) when share >= @move_share, do: :move
  defp decide(true, _count, share) when share <= @succession_share, do: :succession
  defp decide(true, _count, _share), do: :review

  @doc """
  For the episode updater, right after the download and before anything is
  saved: `:move` (no redirect, or one to the same show), or
  `{:not_followed, message}`.
  """
  def check_redirect(_podcast, [], _feed_xml), do: :move

  def check_redirect(podcast, [new_url | _], feed_xml) do
    {new_title, episode_titles} = RssFeed.titles(feed_xml)
    act(podcast, new_url, classify(podcast, new_title, episode_titles))
  end

  @doc """
  For the metadata refresh, which follows redirects with the full feed map
  at hand: `:ok`, or `{:error, message}` for a redirect it must not follow.
  No backlog entry and no email, the episode updater takes care of those.
  """
  def check_refresh_redirect(_podcast, [], _map), do: :ok

  def check_refresh_redirect(podcast, [new_url | _], map) do
    episode_titles = for {_key, episode} <- map[:episodes] || %{}, do: episode[:title]

    case classify(podcast, map[:title], episode_titles) do
      {:move, _share} ->
        :ok

      {_decision, share} ->
        {:error,
         "Podcast #{podcast.id} update rejected: its feed redirects to #{new_url}, " <>
           "a different show (#{percent(share)} of its episodes known)"}
    end
  end

  @doc """
  For the episode updater, before `<itunes:new-feed-url>` is saved: fetches
  the announced feed once and applies the same rules. Returns the map, with
  the new URL removed if it is not to be followed.
  """
  def check_new_feed_url(podcast, feed, map) do
    new_url = map[:new_feed_url]

    with false <- is_nil(new_url) or same_url?(new_url, feed.self_link_url),
         {:ok, %HTTPoison.Response{status_code: 200, body: feed_xml}} <-
           Download.get(new_url, follow_redirect: true),
         {new_title, episode_titles} = RssFeed.titles(feed_xml),
         :move <- act(podcast, new_url, classify(podcast, new_title, episode_titles)) do
      {:ok, map}
    else
      # no new URL, or the current one
      true ->
        {:ok, map}

      {:not_followed, _message} ->
        {:ok, Map.delete(map, :new_feed_url)}

      # don't move away from a working feed to one that doesn't answer
      _not_reachable ->
        Logger.info("#{podcast.id} new-feed-url #{new_url} not reachable, not followed")
        {:ok, Map.delete(map, :new_feed_url)}
    end
  end

  defp same_url?(url, other_url), do: bare(url) == bare(other_url)
  defp bare(url), do: url |> String.trim() |> String.replace(~r/^https?:\/\//i, "")

  defp act(_podcast, _new_url, {:move, _share}), do: :move

  defp act(podcast, new_url, {:succession, share}) do
    add_to_backlog(new_url)

    message =
      "Feed now delivers a different show (#{percent(share)} of its episodes known): " <>
        "#{new_url}, not followed, added to the feed backlog"

    record_message(podcast, message)
    {:not_followed, message}
  end

  defp act(podcast, new_url, {:review, share}) do
    message =
      "Feed now delivers #{new_url} with a new title (#{percent(share)} of its " <>
        "episodes known), not followed, needs a review"

    # one email per case, not one per update
    if podcast.last_error_message != Helpers.to_255(message), do: notify_admin(podcast, message)

    record_message(podcast, message)
    {:not_followed, message}
  end

  defp percent(share), do: "#{round(share * 100)} %"

  defp add_to_backlog(url) do
    unless Repo.exists?(from(f in FeedBacklog, where: f.url == ^url)) or
             Feed.exact_matching([url]) do
      Repo.insert!(%FeedBacklog{url: url})
    end
  end

  # No failure_count: the podcast's own feed works, it must not be retired.
  defp record_message(podcast, message) do
    Podcast.changeset(podcast, %{
      last_error_message: Helpers.to_255(message),
      last_error_occured: now()
    })
    |> Repo.update(force: true)
  end

  # Raised and rescued right here, so the update ends cleanly; logged as an
  # error, the exception goes out by email in prod
  # (Logger.Backends.ExceptionNotification).
  defp notify_admin(podcast, message) do
    raise ReviewNeeded, message: "Podcast #{podcast.id} \"#{podcast.title}\": #{message}"
  rescue
    exception in ReviewNeeded ->
      Logger.error(Exception.format(:error, exception, __STACKTRACE__))
  end
end
