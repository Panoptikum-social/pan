defmodule PanWeb.RssFeedView do
  use Pan.Web, :view

  def render("datatable.json", %{rss_feeds: rss_feeds,
                                 draw: draw,
                                 records_total: records_total,
                                 records_filtered: records_filtered}) do
    %{draw: draw,
      recordsTotal: records_total,
      recordsFiltered: records_filtered,
      data: Enum.map(rss_feeds, &rss_feed_json/1)}
  end


  def rss_feed_json(rss_feed) do
    {:safe, content} = html_escape(truncate_string(rss_feed.content, 255))

    %{id:          rss_feed.id,
      content:     to_string(content),
      podcast_id:  rss_feed.podcast_id,
      actions:     datatable_actions(rss_feed, &rss_feed_path/3)}
  end
end
