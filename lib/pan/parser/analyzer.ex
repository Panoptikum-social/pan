defmodule Pan.Parser.Analyzer do
  alias Pan.Parser.RssFeed

  def call(params, "tag", [:rss, _, value]), do: RssFeed.parse(params, "tag", value)


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

  def call(params, "tag", [:channel, _, value]), do: RssFeed.parse(params, "tag", value)

  def call(params, "tag", [:generator, _, [value]]) do
    Map.merge(params, %{feed: %{ feed_generator: value}})
  end

  def call(params, "tag", [:"feedpress:locale", _, _]), do: params
  def call(params, "tag", [:"fyyd:verify", _, _]), do: params


  def call(params, "tag", [:image, _, value]), do: RssFeed.parse(params, "image", value)


  def call(params, "tag", [:title, _, [value]]), do: Map.merge(params, %{title: value})
  def call(params, "tag", [:"itunes:author", _, [value]]), do: Map.merge(params, %{author: value})
  def call(params, "tag", [:"itunes:summary", _, [value]]), do: Map.merge(params, %{summary: value})
  def call(params, "tag", [:link, _, [value]]), do: Map.merge(params, %{website: value})
  def call(params, "tag", [:description, _, [value]]), do: Map.merge(params, %{description: value})

  def call(params, "tag", [:lastBuildDate, _, [value]]) do
    lastbuilddate = Pan.Parser.Helpers.to_ecto_datetime(value)
    Map.merge(params, %{lastBuildDate: lastbuilddate})
  end

  def call(params, "tag", [:"itunes:image"], attr, _) do
    if params.changes.image_url do
      params
    else
      Map.merge(params, %{image_url: attr[:href], image_title: attr[:href]})
    end
  end

  def call(params, "image", [:title, _, [value]]), do: Map.merge(params, %{image_title: value})
  def call(params, "image", [:url, _, [value]]), do: Map.merge(params, %{image_url: value})
  def call(params, "image", [:link, _, _]), do: params


  def call(params, "tag", [:language, _, [value]]) do
    language = Pan.Repo.get_by(Pan.Language, shortcode: value)
    Map.merge(params, %{languages: [language]})
  end

  def call(params, "tag", [:"atom:contributor", _, [head | tail]]) do
    contributor = derive_contributor_params(%{}, head)
                  |> derive_contributor_params(tail)
    Map.merge(params, %{contributors: [contributor]})
  end

  def derive_contributor_params(contributor, tag) do
    case tag[:name] do
      :"atom:name" ->
        Map.merge(contributor, %{name: hd(tag[:value])})
      :"atom:uri" ->
        Map.merge(contributor, %{uri: hd(tag[:value])})
      _ ->
        contributor
    end
  end


  def call(_, context, [name, _, _]) do
    IO.puts "=== name:"
    IO.puts name
    IO.puts "=== context:"
    IO.puts context
    IO.puts "======"
  end
end
