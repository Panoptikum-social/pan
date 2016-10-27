defmodule Pan.Parser.Analyzer do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Helpers
  defdelegate dm(left, right), to: Pan.Parser.Helpers, as: :deep_merge

#wrappers to dive into
  def call(map, "tag", [:rss,     _, value]), do: Iterator.parse(map, "tag", value)
  def call(map, "tag", [:channel, _, value]), do: Iterator.parse(map, "tag", value)


# simple tags to include in podcast
  def call(_, "tag", [:title,             _, [value]]), do: %{title: value}
  def call(_, "tag", [:"itunes:author",   _, []]), do: %{}
  def call(_, "tag", [:"itunes:author",   _, [value]]), do: %{author: value}
  def call(_, "tag", [:"itunes:summary",  _, []]),      do: %{}
  def call(_, "tag", [:"itunes:summary",  _, [value]]), do: %{summary: value}
  def call(_, "tag", [:link,              _, [value]]), do: %{website: value}
  def call(_, "tag", [:"itunes:explicit", _, [value]]), do: %{explicit: Helpers.boolify(value)}
  def call(_, "tag", [:lastBuildDate,     _, [value]]) do
    %{last_build_date: Helpers.to_ecto_datetime(value)}
  end


# image with fallback to itunes:image
  def call(map, "tag", [:image, _, value]), do: Iterator.parse(map, "image", value)
  def call(_, "image", [:title, _, [value]]), do: %{image_title: value}
  def call(_, "image", [:url,   _, [value]]), do: %{image_url: value}
  def call(map, "image", [:link,  _, _]), do: map

  def call(map, "tag", [:"itunes:image", attr, _]) do
    if map[:image_url], do: map,
                        else: %{image_url: attr[:href],
                                image_title: attr[:href]}
  end

  def call(map, "tag", [:"itunes:image", _, [value]]) do
    if map[:image_url], do: map,
                        else: %{image_url: value}
  end


# Description with fallback to itunes:subtitle
  def call(_, "tag", [:description, _, [value]]), do: %{description: value}

  def call(_, "tag", [:"itunes:subtitle", _, []]), do: %{}
  def call(map, "tag", [:"itunes:subtitle", _, [value]]) do
    if map[:description], do: %{},
                          else: %{description: value}
  end


# simple tags to include into nested structure
  def call(_, "tag", [:generator, _, [value]]), do: %{feed: %{ feed_generator: value}}


# the links are a mixture of the two above
  def call(_, "tag", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "self"  -> %{feed: %{ self_link_title: attr[:title],
                            self_link_url: attr[:href]}}
      "next"  -> %{feed: %{ next_page_url: attr[:href]}}
      "prev"  -> %{feed: %{ prev_page_url: attr[:href]}}
      "first" -> %{feed: %{ first_page_url: attr[:href]}}
      "last"  -> %{feed: %{ last_page_url: attr[:href]}}
      "hub"   -> %{feed: %{ hub_link_url: attr[:href]}}
      "alternate" ->
        uuid = String.to_atom(UUID.uuid1())
        alternate_feed_map = %{uuid => %{title: attr[:title], url: attr[:href]}}
        %{feed: %{alternate_feeds: alternate_feed_map}}
      "payment" -> %{payment_link_title: attr[:title],
                     payment_link_url: String.slice(attr[:href], 0, 255)}
    end
  end

  def call(_, "tag", [:"atom10:link", attr, _]) do
    case attr[:rel] do
      "self"  -> %{feed: %{ self_link_title: attr[:title],
                            self_link_url: attr[:href]}}
      "hub" -> %{}
    end
  end


# tags to ignore
  def call(map, "tag", [:"feedpress:locale", _, _]), do: map
  def call(map, "tag", [:"fyyd:verify", _, _]), do: map
  def call(map, "tag", [:"itunes:block", _, _]), do: map
  def call(map, "tag", [:"itunes:keywords", _, _]), do: map
  def call(map, "tag", [:"media:thumbnail", _, _]), do: map
  def call(map, "tag", [:"media:keywords", _, _]), do: map
  def call(map, "tag", [:"media:category", _, _]), do: map
  def call(map, "tag", [:category, _, _]), do: map
  def call(map, "tag", [:site, _, _]), do: map
  def call(map, "tag", [:docs, _, _]), do: map
  def call(map, "tag", [:"feedburner:info", _, _]), do: map
  def call(map, "tag", [:"media:credit", _, _]), do: map
  def call(map, "tag", [:"media:copyright", _, _]), do: map
  def call(map, "tag", [:"media:rating", _, _]), do: map
  def call(map, "tag", [:"media:description", _, _]), do: map
  def call(map, "tag", [:"copyright", _, _]), do: map
  def call(map, "tag", [:"feedburner:feedFlare", _, _]), do: map
  def call(map, "tag", [:"geo:lat", _, _]), do: map
  def call(map, "tag", [:"geo:long", _, _]), do: map
  def call(map, "tag", [:"creativeCommons:license", _, _]), do: map
  def call(map, "tag", [:"feedburner:emailServiceId", _, _]), do: map
  def call(map, "tag", [:"feedburner:feedburnerHostname", _, _]), do: map
  def call(map, "tag", [:managingEditor, _, _]), do: map
  def call(map, "tag", [:pubDate, _, _]), do: map


  def call(_, "episode", [:"itunes:image", _, _]), do: %{}
  def call(_, "episode", [:"itunes:keywords", _, _]), do: %{}
  def call(_, "episode", [:"post-id", _, _]), do: %{}
  def call(_, "episode", [:author, _, _]), do: %{}
  def call(_, "episode", [:"itunes:explicit", _, _]), do: %{}
  def call(_, "episode", [:category, _, _]), do: %{}
  def call(_, "episode", [:"dc:creator", _, _]), do: %{}
  def call(_, "episode", [:comments, _, _]), do: %{}
  def call(_, "episode", [:"media:content", _, _]), do: %{}
  def call(_, "episode", [:"feedburner:origLink", _, _]), do: %{}
  def call(_, "episode", [:"feedburner:origEnclosureLink", _, _]), do: %{}

# We expect several language tags
  def call(_, "tag", [:language, _, [value]]) do
    uuid = String.to_atom(UUID.uuid1())
    %{languages: %{uuid => %{shortcode: value}}}
  end


# We expect several contributors
  def call(map, "tag", [:"atom:contributor", _, value]) do
    Iterator.parse(map, "contributor", value, UUID.uuid1())
  end

  def call("contributor", [:"atom:name", _, [value]]), do: %{name: value}
  def call("contributor", [:"atom:uri",  _, [value]]), do: %{uri: value}


# We expect one owner
  def call(map, "tag", [:"itunes:owner", _, value]), do: Iterator.parse(map, "owner", value)
  def call(_, "owner", [:"itunes:name",   _, []]), do: %{}
  def call(_, "owner", [:"itunes:name",   _, [value]]), do: %{name: value}
  def call(_, "owner", [:"itunes:email",  _, []]), do: %{}
  def call(_, "owner", [:"itunes:email",  _, [value]]), do: %{email: value}


# Parsing categories infintely deep
  def call(_, "tag", [:"itunes:category", _, []]), do: %{}
  def call(_, "tag", [:"itunes:category", attr, [value]]) do
    {:ok, category} = Pan.Parser.Category.find_or_create(attr[:text], nil)
    map = %{categories: %{category.id => true}}
    call(map, "category", [value[:name], value[:attr], value[:value]], category.id)
  end

  def call(map, "category", [nil, nil, nil], _), do: map
  def call(map, "category", [:"itunes:category", attr, []], parent_id) do
    {:ok, category} = Pan.Parser.Category.find_or_create(attr[:text], parent_id)
    Helpers.deep_merge(map, %{categories: %{category.id => true}})
  end

  def call(map, "category", [:"itunes:category", attr, [value]], parent_id) do
    {:ok, category} = Pan.Parser.Category.find_or_create(attr[:text], parent_id)
    Helpers.deep_merge(map, %{categories: %{category.id => true}})
    |> call("category", [value[:name], value[:attr], value[:value]], category.id)
  end


# Episodes
  def call(map, "tag", [:item, _, value]), do: Iterator.parse(map, "episode", value, UUID.uuid1())

  def call(_, "episode", [:title,             _, [value]]), do: %{title:       String.slice(value, 0, 255)}
  def call(_, "episode", [:link,              _, [value]]), do: %{link:        String.slice(value, 0, 255)}
  def call(_, "episode", [:guid,              _, [value]]), do: %{guid:        String.slice(value, 0, 255)}
  def call(_, "episode", [:description,       _, []]), do: %{}
  def call(_, "episode", [:description,       _, [value]]), do: %{description: value}
  def call(_, "episode", [:"content:encoded", _, []]), do: %{}
  def call(_, "episode", [:"content:encoded", _, [value]]), do: %{shownotes:   HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:"itunes:summary",  _, []]), do: %{}
  def call(_, "episode", [:"itunes:summary",  _, [value]]), do: %{summary:     value}
  def call(_, "episode", [:"itunes:subtitle", _, []]), do: %{}
  def call(_, "episode", [:"itunes:subtitle", _, [value]]), do: %{subtitle:    String.slice(value, 0, 255)}
  def call(_, "episode", [:"itunes:author",   _, []]), do: %{}
  def call(_, "episode", [:"itunes:author",   _, [value]]), do: %{author:      String.slice(value, 0, 255)}
  def call(_, "episode", [:"itunes:duration", _, [value]]), do: %{duration:    value}

  def call(_, "episode", [:pubDate,           _, [value]]) do
    %{publishing_date: Helpers.to_ecto_datetime(value)}
  end

  def call(_, "episode", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "http://podlove.org/deep-link" -> %{deep_link: String.slice(attr[:href], 0, 255)}
      "payment" ->                      %{payment_link_title: attr[:title],
                                          payment_link_url: String.slice(attr[:href], 0, 255)}
    end
  end


# Enclosures a.k.a. Audiofiles
  def call(_, "episode", [:enclosure, attr, _]) do
    enclosure_map = %{url: attr[:url], length: attr[:length], type: attr[:type], guid: attr[:"bitlove:guid"]}
    uuid = String.to_atom(UUID.uuid1())
    %{enclosures: %{uuid => enclosure_map}}
  end


# Chapters
  def call(_, "episode", [:"psc:chapters", _, value]) do
    Iterator.parse(%{}, "chapter", value)
  end

  def call("chapter", [:"psc:chapter", attr, _]) do
    chapter_uuid = String.to_atom(UUID.uuid1())
    %{chapter_uuid => %{start: attr[:start], title: String.slice(attr[:title], 0, 255)}}
  end


# Episode contributors
  def call(_, "episode", [:"atom:contributor", _, value]) do
    contributor_uuid = String.to_atom(UUID.uuid1())
    Iterator.parse(%{contributors: %{contributor_uuid => %{}}}, "episode-contributor", value, contributor_uuid)
  end

  def call("episode-contributor", [:"atom:name", _ , [value]]), do: %{name: value}
  def call("episode-contributor", [:"atom:uri",  _ , [value]]), do: %{uri: value}
end