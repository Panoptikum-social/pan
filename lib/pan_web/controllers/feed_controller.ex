defmodule PanWeb.FeedController do
  use PanWeb, :controller
  alias PanWeb.{AlternateFeed, Feed}

  plug(:scrub_params, "feed" when action in [:create, :update])

  def make_only(conn, %{"id" => id}) do
    primary_feed = Repo.get!(Feed, id)

    other_feeds =
      Repo.all(
        from(f in Feed,
          where:
            f.podcast_id == ^primary_feed.podcast_id and
              f.id != ^primary_feed.id
        )
      )

    for feed <- other_feeds do
      # move alternate feeds over to primary feed
      from(a in AlternateFeed, where: a.feed_id == ^feed.id)
      |> Repo.update_all(set: [feed_id: primary_feed.id])

      # create replacement
      %AlternateFeed{feed_id: primary_feed.id, title: feed.self_link_url, url: feed.self_link_url}
      |> Repo.insert()

      Repo.delete!(feed)
    end

    conn
    |> put_flash(:info, "Feed made primary successfully.")
    |> redirect(to: podcast_path(conn, :show, primary_feed.podcast_id))
  end
end
