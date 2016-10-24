defmodule Pan.Parser.Analyzer do
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Helpers

#wrappers to dive into
  def call(params, "tag", [:rss,     _, value]), do: RssFeed.parse(params, "tag", value)
  def call(params, "tag", [:channel, _, value]), do: RssFeed.parse(params, "tag", value)


# simple tags to include in podcast
  def call(params, "tag", [:title,            _, [value]]), do: Map.merge(params, %{title: value})
  def call(params, "tag", [:"itunes:author",  _, [value]]), do: Map.merge(params, %{author: value})
  def call(params, "tag", [:"itunes:summary", _, [value]]), do: Map.merge(params, %{summary: value})
  def call(params, "tag", [:link,             _, [value]]), do: Map.merge(params, %{website: value})
  def call(params, "tag", [:lastBuildDate,    _, [value]]) do
    Map.merge(params, %{lastBuildDate: Helpers.to_ecto_datetime(value)})
  end
  def call(params, "tag", [:"itunes:explicit",         _, [value]]) do
    Map.merge(params, %{explicit: Helpers.boolify(value)})
  end


# image with fallback to itunes:image
  def call(params, "tag", [:image, _, value]), do: RssFeed.parse(params, "image", value)

  def call(params, "image", [:title, _, [value]]), do: Map.merge(params, %{image_title: value})
  def call(params, "image", [:url,   _, [value]]), do: Map.merge(params, %{image_url: value})
  def call(params, "image", [:link,  _, _]), do: params

  def call(params, "tag", [:"itunes:image", attr, _]) do
    unless params[:image_url], do: params = Map.merge(params, %{image_url: attr[:href],
                                                                image_title: attr[:href]})
    params
  end

  def call(params, "tag", [:"itunes:image", _, [value]]) do
    unless params[:image_url], do: params = Map.merge(params, %{image_url: value})
    params
  end


# Description with fallback to itunes:subtitle
  def call(params, "tag", [:description,      _, [value]]), do: Map.merge(params, %{description: value})

  def call(params, "tag", [:"itunes:subtitle", _, [value]]) do
    unless params[:description], do: params = Map.merge(params, %{description: value})
    params
  end


# simple tags to include into nested structure
  def call(params, "tag", [:generator, _, [value]]) do
    Map.merge(params, %{feed: %{ feed_generator: value}})
  end


# the links are a mixture of the two above
  def call(params, "tag", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "self"  ->
        Helpers.deep_merge(params, %{feed: %{ self_link_title: attr[:title],
                                     self_link_url: attr[:href]}})
      "next"  ->
        Helpers.deep_merge(params, %{feed: %{ next_page_url: attr[:href]}})
      "prev"  ->
        Helpers.deep_merge(params, %{feed: %{ prev_page_url: attr[:href]}})
      "first" ->
        Helpers.deep_merge(params, %{feed: %{ first_page_url: attr[:href]}})
      "last"  ->
        Helpers.deep_merge(params, %{feed: %{ last_page_url: attr[:href]}})
      "hub"   ->
        Helpers.deep_merge(params, %{feed: %{ hub_page_url: attr[:href]}})
      "alternate" ->
        uuid = String.to_atom(UUID.uuid1())
        alternate_feed_params = %{uuid => %{title: attr[:title], url: attr[:href]}}
        Helpers.deep_merge(params, %{feed: %{alternate_feeds: alternate_feed_params}})
      "payment" ->
        Helpers.deep_merge(params, %{payment_link_title: attr[:title],
                                     payment_link_url: String.slice(attr[:href], 0, 255)})
    end
  end


# tags to ignore
  def call(params, "tag", [:"feedpress:locale", _, _]), do: params
  def call(params, "tag", [:"fyyd:verify", _, _]), do: params
  def call(params, "tag", [:"itunes:block", _, _]), do: params


# We expect several language tags
  def call(params, "tag", [:language, _, [value]]) do
#FIXME: We need a find_or_create_by here
    language = Pan.Repo.get_by(Pan.Language, shortcode: value)
    Map.merge(params, %{languages: [language.id]})
  end


# We expect several contributors
  def call(params, "tag", [:"atom:contributor", _, value]) do
    RssFeed.parse(params, "contributor", value, UUID.uuid1())
  end

  def call("contributor", [:"atom:name", _, [value]]), do: %{name: value}
  def call("contributor", [:"atom:uri",  _, [value]]), do: %{uri: value}


# We expect one owner
  def call(params, "tag", [:"itunes:owner", _, value]), do: RssFeed.parse(params, "owner", value)

  def call(params, "owner", [:"itunes:name",   _, [value]]), do: Map.merge(params, %{name: value})
  def call(params, "owner", [:"itunes:email",  _, [value]]), do: Map.merge(params, %{uri: value})



# Parsing categories infintely deep
  def call(params, "tag", [:"itunes:category", attr, []]), do: params
  def call(params, "tag", [:"itunes:category", attr, [value]]) do
    category = Pan.Parser.Category.get_or_create(attr[:text], nil)
    Map.merge(params, %{categories: [category.id]})
    |> call("category", [value[:name], value[:attr], value[:value]], category.id)
  end

  def call(params, "category", [:"itunes:category", attr, []], parent_id), do: params
  def call(params, "category", [:"itunes:category", attr, [value]], parent_id) do
    category = Pan.Parser.Category.get_or_create(attr[:text], parent_id)
    Map.merge(params, %{categories: [category.id]})
    |> call("category", [value[:name], value[:attr], value[:value]], category.id)
  end


# Episodes
  def call(params, "tag", [:item, _, value]), do: RssFeed.parse(params, "episode", value, UUID.uuid1())

  def call("episode", [:title,             _, [value]]), do: %{title:       String.slice(value, 0, 255)}
  def call("episode", [:link,              _, [value]]), do: %{link:        String.slice(value, 0, 255)}
  def call("episode", [:guid,              _, [value]]), do: %{guid:        String.slice(value, 0, 255)}
  def call("episode", [:description,       _, [value]]), do: %{description: value}
  def call("episode", [:"content:encoded", _, [value]]), do: %{shownotes:   value}
  def call("episode", [:"itunes:summary",  _, [value]]), do: %{summary:     value}
  def call("episode", [:"itunes:subtitle", _, [value]]), do: %{subtitle:    String.slice(value, 0, 255)}
  def call("episode", [:"itunes:author",   _, [value]]), do: %{author:      String.slice(value, 0, 255)}
  def call("episode", [:"itunes:duration", _, [value]]), do: %{duration:    value}

  def call("episode", [:pubDate,           _, [value]]) do
    %{publishing_date: Helpers.to_ecto_datetime(value)}
  end

  def call("episode", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "http://podlove.org/deep-link" -> %{deep_link: String.slice(attr[:href], 0, 255)}
      "payment" ->                      %{title: attr[:title], url: attr[:href]}
    end
  end

  def call("episode", [:enclosure, attr, _]) do
    enclosure_params = %{url: attr[:url], length: attr[:length], type: attr[:type], guid: attr[:"bitlove:guid"]}
    uuid = String.to_atom(UUID.uuid1())
    %{enclosures: %{uuid => enclosure_params}}
  end

# Print unknown tags to standard out
  def call(params, context, [name, attr, _]) do
    IO.puts "===================================="
    IO.inspect params
    IO.puts "======"
    IO.puts "- name:"
    IO.inspect name
    IO.puts "- context:"
    IO.inspect context
    IO.puts "- attr:"
    IO.inspect attr
    IO.puts "===================================="
  end
end