defmodule Pan.Repo.Migrations.MovePodbeanFeedsOffPbcdn1 do
  use Ecto.Migration

  # Podbean feeds at https://pbcdn1.podbean.com/<slug>/feed.xml answer 403
  # (S3 AccessDenied, no redirect), the same feeds are alive at
  # https://feed.podbean.com/<slug>/feed.xml. Rewrites them like
  # Pan.Parser.Feed.update_with_redirect_target/2 would: the old URL is kept
  # in alternate_feeds as history. Active podcasts are made due now, so the
  # updater re-fetches them right away instead of after their backed-off
  # interval. Retired podcasts get the new URL but stay retired.
  @old_url "^https?://pbcdn1\\.podbean\\.com/([^/]+)/feed\\.xml$"
  @new_url "https://feed.podbean.com/\\1/feed.xml"

  def up do
    run("alternate_feeds rows added", """
    INSERT INTO alternate_feeds (feed_id, url, title, inserted_at, updated_at)
    SELECT f.id, f.self_link_url, f.self_link_url, now(), now()
    FROM feeds f
    WHERE f.self_link_url ~ '#{@old_url}'
      AND NOT EXISTS (
        SELECT 1 FROM alternate_feeds a
        WHERE a.feed_id = f.id AND a.url = f.self_link_url
      )
    """)

    run("podcasts made due now", """
    UPDATE podcasts p
    SET next_update = now()
    FROM feeds f
    WHERE f.podcast_id = p.id
      AND f.self_link_url ~ '#{@old_url}'
      AND NOT p.retired
      AND NOT p.update_paused
    """)

    run("feeds moved to feed.podbean.com", """
    UPDATE feeds
    SET self_link_url = regexp_replace(self_link_url, '#{@old_url}', '#{@new_url}'),
        updated_at = now()
    WHERE self_link_url ~ '#{@old_url}'
    """)
  end

  defp run(label, sql) do
    %{num_rows: num_rows} = repo().query!(sql)
    IO.puts("#{label}: #{num_rows}")
  end

  # Not reversible: the old URLs stay in alternate_feeds, but nothing tells
  # the feeds moved here from those that were on feed.podbean.com already.
  def down, do: :ok
end
