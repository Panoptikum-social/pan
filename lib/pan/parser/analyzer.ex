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
        Map.merge(params, %{feed: %{ self_link_title: attr[:title],
                                     self_link_url:   attr[:href]}})
      "next"  ->
        Map.merge(params, %{feed: %{ next_page_url:   attr[:href]}})
      "prev"  ->
        Map.merge(params, %{feed: %{ prev_page_url:   attr[:href]}})
      "first" ->
        Map.merge(params, %{feed: %{ first_page_url:  attr[:href]}})
      "last"  ->
        Map.merge(params, %{feed: %{ last_page_url:   attr[:href]}})
      "hub"   ->
        Map.merge(params, %{feed: %{ hub_page_url:    attr[:href]}})
      "alternate" ->
        Map.merge(params, %{feed: %{alternate_feeds: [ %{title: attr[:title],
                                                         url:   attr[:href]}]}})
      "payment" ->
        Map.merge(params, %{payment_link_title: attr[:title],
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
  def call(params, "tag", [:"atom:contributor", _, value]), do: RssFeed.parse(params, "contributor", value, UUID.uuid1())

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

  def call(params, "episode", [:title, _, [value]]), do: Map.merge(params, %{title: value})



# Print unknown tags to standard out
  def call(_, context, [name, _, _]) do
    IO.puts "=== name:"
    IO.puts name
    IO.puts "=== context:"
    IO.puts context
    IO.puts "======"
  end
end