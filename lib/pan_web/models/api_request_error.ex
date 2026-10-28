defmodule PanWeb.ApiRequestError do
  @moduledoc """
  A failed API request on a podcast (status 400 or higher), recorded by
  PanWeb.Api.PodcastController for the moderators' API error page
  (PanWeb.Live.Moderation.ApiErrors). Rows older than a week are deleted
  whenever a new one is recorded.
  """
  use PanWeb, :model
  alias Pan.Parser.Helpers
  alias Pan.Repo
  alias PanWeb.{ApiRequestError, Feed, FormerPodcast, Podcast}

  @kept_days 7

  schema "api_request_errors" do
    field(:podcast_id, :integer)
    field(:endpoint, :string)
    field(:status, :integer)
    field(:title, :string)
    field(:detail, :string)

    timestamps(updated_at: false)
  end

  def record(podcast_id, endpoint, status, title, detail) do
    from(e in ApiRequestError,
      where: e.inserted_at < ^hours_ago(@kept_days * 24)
    )
    |> Repo.delete_all()

    Repo.insert!(%ApiRequestError{
      podcast_id: podcast_id,
      endpoint: endpoint,
      status: status,
      title: Helpers.to_255(title),
      detail: Helpers.to_255(detail)
    })
  end

  @doc """
  The failed requests of the last 24 hours on podcasts of the category, plus
  those on podcasts that no longer exist (with their PanWeb.FormerPodcast
  if known), one entry per podcast with its latest error, newest first.
  """
  def last_day_by_podcast(category_id) do
    podcast_ids = Podcast.ids_by_category_id(category_id)

    from(e in ApiRequestError,
      left_join: p in Podcast,
      on: p.id == e.podcast_id,
      left_join: f in FormerPodcast,
      on: f.id == e.podcast_id,
      # every podcast has exactly one feed
      left_join: feed in Feed,
      on: feed.podcast_id == p.id,
      where:
        e.inserted_at > ^hours_ago(24) and not is_nil(e.podcast_id) and
          (e.podcast_id in ^podcast_ids or is_nil(p.id)),
      order_by: [desc: e.inserted_at, desc: e.id],
      select: {e, p.title, f, feed.id}
    )
    |> Repo.all()
    |> Enum.group_by(fn {error, _title, _former, _feed_id} -> error.podcast_id end)
    |> Enum.map(fn {podcast_id, [{latest, podcast_title, former, feed_id} | _] = errors} ->
      %{
        podcast_id: podcast_id,
        podcast_title: podcast_title,
        former: former,
        feed_id: feed_id,
        latest: latest,
        count: length(errors),
        endpoints:
          errors
          |> Enum.map(fn {error, _title, _former, _feed_id} -> error.endpoint end)
          |> Enum.uniq()
      }
    end)
    |> Enum.sort_by(& &1.latest.inserted_at, {:desc, NaiveDateTime})
  end

  # in Elixir, not SQL: the prod database session doesn't run in UTC
  defp hours_ago(hours), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-hours * 3600)
end
