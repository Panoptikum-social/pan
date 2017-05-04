defmodule Pan.FeedView do
  use Pan.Web, :view
  alias Pan.Endpoint

  def render("datatable.json", %{feeds: feeds}) do
    %{feeds: Enum.map(feeds, &feed_json/1)}
  end

  def feed_json(feed) do
    %{id:              feed.id,
      self_link_title: feed.self_link_title,
      self_link_url:   "<a href='#{feed.self_link_url}'>#{feed.self_link_url}</a>",
      feed_generator:  feed.feed_generator,
      podcast_id:      "<a href='/admin/podcasts/#{feed.podcast_id}'>#{feed.podcast_id}</a>",
      podcast_title:   feed.podcast_title,
      actions:         feed_actions(feed, &feed_path/3)}
  end


  def feed_actions(record, path) do
    ["<nobr>",
     link("Make primary", to: path.(Endpoint, :make_only, record.id),
                          class: "btn btn-info btn-xs",
                          method: :post), " ",
     link("Show", to: path.(Endpoint, :show, record.id),
                  class: "btn btn-default btn-xs"), " ",
     link("Edit", to: path.(Endpoint, :edit, record.id),
                  class: "btn btn-warning btn-xs"), " ",
     link("Delete", to: path.(Endpoint, :delete, record.id),
                    class: "btn btn-danger btn-xs",
                    method: :delete,
                    data: [confirm: "Are you sure?"]),
     "</nobr>"]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end
end
