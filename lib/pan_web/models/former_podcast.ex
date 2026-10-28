defmodule PanWeb.FormerPodcast do
  @moduledoc """
  A deleted podcast under its old id, with the podcast it was merged into
  (`new_id`, nil for a plain deletion). Recorded by the admin delete and by
  PanWeb.PodcastMerge, so the API can tell a client what became of an id it
  still uses. Older ones were seeded from the prod journal.
  """
  use PanWeb, :model
  alias Pan.Parser.Helpers
  alias Pan.Repo
  alias PanWeb.{Feed, FormerPodcast}

  @primary_key {:id, :integer, autogenerate: false}
  schema "former_podcasts" do
    field(:title, :string)
    field(:feed_url, :string)
    field(:new_id, :integer)
    field(:deleted_at, :naive_datetime)
  end

  @doc "Call before the podcast is deleted, while its feed still exists."
  def record(podcast, new_id \\ nil) do
    feed_url =
      from(f in Feed,
        where: f.podcast_id == ^podcast.id,
        order_by: f.id,
        limit: 1,
        select: f.self_link_url
      )
      |> Repo.one()

    Repo.insert!(
      %FormerPodcast{
        id: podcast.id,
        title: Helpers.to_255(podcast.title),
        feed_url: Helpers.to_255(feed_url),
        new_id: new_id,
        deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      on_conflict: :replace_all,
      conflict_target: :id
    )

    # podcasts merged into this one earlier now live on in the new one
    from(f in FormerPodcast, where: f.new_id == ^podcast.id)
    |> Repo.update_all(set: [new_id: new_id])
  end

  @doc "What the API answers for an id that is no podcast (any more): {detail, meta}."
  def not_found(id) do
    case Repo.get(FormerPodcast, id) do
      %FormerPodcast{new_id: new_id, title: title} when not is_nil(new_id) ->
        {"Podcast with Panoptikum ID #{id} (#{title}) was merged into the podcast with " <>
           "Panoptikum ID #{new_id}, please use that ID.", %{new_id: new_id}}

      %FormerPodcast{title: title} ->
        {"Podcast with Panoptikum ID #{id} (#{title}) was deleted.", nil}

      nil ->
        {"Podcast with Panoptikum ID #{id} no longer exists.", nil}
    end
  end
end
