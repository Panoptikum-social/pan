defmodule Pan.Parser.Analyzer do
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Helpers
  defdelegate dm(left, right), to: Pan.Parser.Helpers, as: :deep_merge

#wrappers to dive into
  def call(map, "tag", [:rss,     _, value]), do: RssFeed.parse(map, "tag", value)

  def call(map, "tag", [:channel, _, value]), do: RssFeed.parse(map, "tag", value)


# simple tags to include in podcast
  def call(_, "tag", [:title,             _, [value]]), do: %{title: value}

  def call(_, "tag", [:"itunes:author",   _, [value]]), do: %{author: value}

  def call(_, "tag", [:"itunes:summary",  _, [value]]), do: %{summary: value}

  def call(_, "tag", [:link,              _, [value]]), do: %{website: value}

  def call(_, "tag", [:"itunes:explicit", _, [value]]), do: %{explicit: Helpers.boolify(value)}

  def call(_, "tag", [:lastBuildDate,     _, [value]]) do
    %{lastBuildDate: Helpers.to_ecto_datetime(value)}
  end


# image with fallback to itunes:image
  def call(map, "tag", [:image, _, value]), do: RssFeed.parse(map, "image", value)

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

  def call(map, "tag", [:"itunes:subtitle", _, [value]]) do
    if map[:description], do: map,
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
      "hub"   -> %{feed: %{ hub_page_url: attr[:href]}}
      "alternate" ->
        uuid = String.to_atom(UUID.uuid1())
        alternate_feed_map = %{uuid => %{title: attr[:title], url: attr[:href]}}
        %{feed: %{alternate_feeds: alternate_feed_map}}
      "payment" -> %{payment_link_title: attr[:title],
                     payment_link_url: String.slice(attr[:href], 0, 255)}
    end
  end


# tags to ignore
  def call(map, "tag", [:"feedpress:locale", _, _]), do: map

  def call(map, "tag", [:"fyyd:verify", _, _]),      do: map

  def call(map, "tag", [:"itunes:block", _, _]),     do: map


# We expect several language tags
  def call(_, "tag", [:language, _, [value]]) do
#FIXME: We need a find_or_create_by here
    language = Pan.Repo.get_by(Pan.Language, shortcode: value)
    %{languages: [language.id]}
  end


# We expect several contributors
  def call(map, "tag", [:"atom:contributor", _, value]) do
    RssFeed.parse(map, "contributor", value, UUID.uuid1())
  end

  def call("contributor", [:"atom:name", _, [value]]), do: %{name: value}

  def call("contributor", [:"atom:uri",  _, [value]]), do: %{uri: value}


# We expect one owner
  def call(map, "tag", [:"itunes:owner", _, value]), do: RssFeed.parse(map, "owner", value)

  def call(_, "owner", [:"itunes:name",   _, [value]]), do: %{name: value}

  def call(_, "owner", [:"itunes:email",  _, [value]]), do: %{uri: value}


# Parsing categories infintely deep
  def call(_, "tag", [:"itunes:category", _, []]), do: %{}

  def call(_, "tag", [:"itunes:category", attr, [value]]) do
    category = Pan.Parser.Category.get_or_create(attr[:text], nil)
    %{categories: [category.id]}
    |> call("category", [value[:name], value[:attr], value[:value]], category.id)
  end

  def call(map, "category", [:"itunes:category", _, []], _), do: map

  def call(_, "category", [:"itunes:category", attr, [value]], parent_id) do
    category = Pan.Parser.Category.get_or_create(attr[:text], parent_id)
    %{categories: [category.id]}
    |> call("category", [value[:name], value[:attr], value[:value]], category.id)
  end


# Episodes
  def call(map, "tag", [:item, _, value]), do: RssFeed.parse(map, "episode", value, UUID.uuid1())

  def call(_, "episode", [:title,             _, [value]]), do: %{title:       String.slice(value, 0, 255)}
  def call(_, "episode", [:link,              _, [value]]), do: %{link:        String.slice(value, 0, 255)}
  def call(_, "episode", [:guid,              _, [value]]), do: %{guid:        String.slice(value, 0, 255)}
  def call(_, "episode", [:description,       _, [value]]), do: %{description: value}
  def call(_, "episode", [:"content:encoded", _, [value]]), do: %{shownotes:   value}
  def call(_, "episode", [:"itunes:summary",  _, [value]]), do: %{summary:     value}
  def call(_, "episode", [:"itunes:subtitle", _, [value]]), do: %{subtitle:    String.slice(value, 0, 255)}
  def call(_, "episode", [:"itunes:author",   _, [value]]), do: %{author:      String.slice(value, 0, 255)}
  def call(_, "episode", [:"itunes:duration", _, [value]]), do: %{duration:    value}

  def call(_, "episode", [:pubDate,           _, [value]]) do
    %{publishing_date: Helpers.to_ecto_datetime(value)}
  end

  def call(_, "episode", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "http://podlove.org/deep-link" -> %{deep_link: String.slice(attr[:href], 0, 255)}
      "payment" ->                      %{title: attr[:title], url: attr[:href]}
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
    RssFeed.parse(%{}, "chapter", value)
  end

  def call("chapter", [:"psc:chapter", attr, _]) do
    chapter_uuid = String.to_atom(UUID.uuid1())
    %{chapter_uuid => %{start: attr[:start], title: attr[:title]}}
  end


# Episode contributors
  def call(_, "episode", [:"atom:contributor", _, value]) do
    contributor_uuid = String.to_atom(UUID.uuid1())
    RssFeed.parse(%{contributors: %{contributor_uuid => %{}}}, "episode-contributor", value, contributor_uuid)
  end

  def call("episode-contributor", [:"atom:name", _ , [value]]), do: %{name: value}
  def call("episode-contributor", [:"atom:uri",  _ , [value]]), do: %{uri: value}
end