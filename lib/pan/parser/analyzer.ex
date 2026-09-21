defmodule Pan.Parser.Analyzer do
  import Pan.Parser.Iterator, only: [parse: 3, parse: 4]
  import UUID, only: [uuid1: 0]

  import Pan.Parser.Helpers,
    only: [
      to_255: 1,
      scrub: 1,
      to_naive_datetime: 1,
      boolify: 1,
      strip_tags: 1,
      flatten_to_string: 1
    ]

  import Pan.Parser.MyDateTime, only: [now: 0]

  defdelegate dm(left, right), to: Pan.Parser.Helpers, as: :deep_merge

  # wrappers to dive into
  def call(map, "tag", [:rss, _, value]), do: parse(map, "tag", value)
  def call(map, "tag", [:channel, _, value]), do: parse(map, "tag", value)

  # simple tags to include in podcast
  def call(_, "tag", [:title, _, []]), do: %{}

  def call(_, "tag", [:title, _, values = [_ | _]]),
    do: %{title: to_255(flatten_to_string(values))}

  def call(_, "tag", [:"itunes:summary", _, []]), do: %{}

  def call(_, "tag", [:"itunes:summary", _, values = [_ | _]]),
    do: %{summary: flatten_to_string(values)}

  def call(_, "tag", [:link, _, []]), do: %{}
  def call(_, "tag", [:link, _, [value]]), do: %{website: value}

  def call(_, "tag", [:"itunes:new-feed-url", _, []]), do: %{}
  def call(_, "tag", [:"new-feed-url", _, [value]]), do: %{new_feed_url: value}
  def call(_, "tag", [:"itunes:new-feed-url", _, [value]]), do: %{new_feed_url: value}

  def call(_, "tag", [tag_atom, _, [value]])
      when tag_atom in [
             :"itunes:explicit",
             :"iTunes:explicit",
             :explicit
           ],
      do: %{explicit: boolify(value)}

  def call(_, "tag", [:lastBuildDate, _, [value]]) do
    %{last_build_date: to_naive_datetime(value)}
  end

  def call(_, "tag", [:"dc:date", _, [value]]) do
    %{last_build_date: to_naive_datetime(value)}
  end

  def call(_, "tag", [:pubdate, _, []]), do: %{}
  def call(_, "tag", [:pubDate, _, []]), do: %{}
  def call(_, "tag", [:pubdate, _, [value]]), do: %{last_build_date: to_naive_datetime(value)}
  def call(_, "tag", [:pubDate, _, [value]]), do: %{last_build_date: to_naive_datetime(value)}
  def call(_, "tag", [:PubDate, _, [value]]), do: %{last_build_date: to_naive_datetime(value)}
  def call(_, "tag", [:lastPubDate, _, [value]]), do: %{last_build_date: to_naive_datetime(value)}

  # image with fallback to itunes:image
  def call(_, "tag", [:image, _, value]), do: parse(%{}, "image", value)

  def call(_, "image", [:title, _, [value]]) when is_binary(value),
    do: %{image_title: to_255(value)}

  def call(_, "image", [:title, _, _]), do: %{}
  def call(_, "image", [:url, _, []]), do: %{}
  def call(_, "image", [:url, _, [value]]), do: %{image_url: to_255(value)}
  def call(_, "image", [:link, _, _]), do: %{}
  def call(_, "image", [:description, _, _]), do: %{}
  def call(_, "image", [:width, _, _]), do: %{}
  def call(_, "image", [:height, _, _]), do: %{}

  def call(map, "image", [tag_atom, attr, _])
      when tag_atom in [
             :"itunes:image",
             :"iTunes:image"
           ] do
    if map[:image_url],
      do: map,
      else: %{image_url: to_255(attr[:href]), image_title: to_255(attr[:href])}
  end

  def call(map, "tag", [tag_atom, attr, _])
      when tag_atom in [
             :"itunes:image",
             :"iTunes:image"
           ] do
    if map[:image_url],
      do: map,
      else: %{image_url: to_255(attr[:href]), image_title: to_255(attr[:href])}
  end

  def call(map, "tag", [tag_atom, _, [value]])
      when tag_atom in [
             :"itunes:image",
             :"iTunes:image"
           ] do
    if map[:image_url],
      do: map,
      else: %{image_url: to_255(value)}
  end

  def call(_, "tag", [tag_atom, _, []]) when tag_atom in [:description, :"itunes:subtitle"],
    do: %{}

  def call(_, "tag", [:description, _, values = [_ | _]]),
    do: %{description: flatten_to_string(values)}

  def call(_, "tag", [:"itunes:description", _, values = [_ | _]]),
    do: %{description: flatten_to_string(values)}

  def call(_, "tag", [:"itunes:description", [text: value], _]), do: %{description: value}

  def call(map, "tag", [tag_atom, _, [value]])
      when tag_atom in [
             :"itunes:subtitle",
             :"iTunes:subtitle",
             :subtitle
           ] do
    if map[:description],
      do: %{},
      else: %{description: value}
  end

  # simple tags to include into nested structure
  def call(_, "tag", [:generator, _, []]), do: %{}
  def call(_, "tag", [:generator, _, [value]]), do: %{feed: %{feed_generator: value}}

  # the links are a mixture of the two above
  def call(_, "tag", [:"atom:link", attr, _]), do: parse_atom_link(attr)

  def call(_, "tag", [:"rawvoice:donate", attr, [value]]),
    do: %{payment_link_title: value, payment_link_url: attr[:href]}

  def call(_, "tag", [:"rawvoice:donate", attr, []]),
    do: %{payment_link_title: attr[:href], payment_link_url: attr[:href]}

  def call(_, "tag", [:"atom10:link", attr, _]) do
    case attr[:rel] do
      "self" -> %{feed: %{self_link_title: attr[:title], self_link_url: attr[:href]}}
      "hub" -> %{}
    end
  end

  # We expect several language tags
  def call(_, "tag", [:language, _, []]), do: %{}
  def call(_, "tag", [tag_atom, _, [_]]) when tag_atom in [:"rtl:credit"], do: %{}

  def call(_, "tag", [tag_atom, _, [value]]) when tag_atom in [:language, :"dc:language"] do
    %{languages: %{uuid1() => %{shortcode: value}}}
  end

  # We expect one owner
  def call(_, "tag", [tag_atom, _, value])
      when tag_atom in [
             :"itunes:owner",
             :owner,
             :"itunes:email"
           ],
      do: parse(%{}, :podcast_contributor, "owner", value)

  # We expect one podcast author
  def call(_, "tag", [:"itunes:author", _, []]), do: %{}

  def call(_, "tag", [tag_atom, _, value])
      when tag_atom in [
             :"itunes:author",
             :"atom:author",
             :author,
             :artist
           ],
      do: parse(%{}, :podcast_contributor, "author", value)

  def call(_, "tag", [tag_atom, _, value])
      when tag_atom in [
             :managingEditor,
             :managingeditor,
             :manageEditor
           ] do
    parse(%{}, :podcast_contributor, "managing_editor", value)
  end

  # Parsing categories infintely deep
  def call(_, "tag", [:"itunes:category", attr, []]) do
    %{categories: %{uuid1() => %{title: attr[:text], parent: nil}}}
  end

  def call(_, "tag", [:"itunes:category", [], [value]]) do
    %{categories: %{uuid1() => %{title: value, parent: nil}}}
  end

  def call(_, "tag", [:"itunes:category", attr, value]) do
    parse(
      %{categories: %{uuid1() => %{title: attr[:text], parent: nil}}},
      "category",
      value,
      attr[:text]
    )
  end

  def call("category", [:"itunes:category", attr, []], parent_title) do
    %{categories: %{uuid1() => %{title: attr[:text], parent: parent_title}}}
  end

  def call("category", [:"itunes:category", attr, value], parent_title) do
    parse(
      %{categories: %{uuid1() => %{title: attr[:text], parent: parent_title}}},
      "category",
      value,
      attr[:text]
    )
  end

  # Not a standard Apple tag at all (the real spec nests itunes:category
  # inside itunes:category) — some feed generators emit this instead, in
  # either casing seen in the wild. Ignored either way: real category data
  # comes through the itunes:category clauses above.
  def call("category", [:"itunes:Subcategory", _, _], _), do: %{}
  def call("category", [:"itunes:subcategory", _, _], _), do: %{}

  # Any other child of an itunes:category (crashed with a FunctionClauseError)
  def call("category", _element, _parent_title), do: %{}

  # Episodes
  def call(map, "tag", [:item, _, value]), do: parse(map, "episode", value, uuid1())
  def call(map, "episode", [:item, _, value]), do: parse(map, "episode", value, uuid1())

  def call(_, "episode", [:title, _, []]), do: %{title: "No title"}

  def call(_, "episode", [:title, _, values = [_ | _]]),
    do: %{title: to_255(flatten_to_string(values))}

  def call(_, "episode", [:"itunes:title", _, []]), do: %{title: "No title"}

  def call(_, "episode", [:"itunes:title", _, [%{name: :"content:encoded", value: [value]}]]),
    do: %{title: strip_tags(value)}

  def call(_, "episode", [:"itunes:title", _, values = [_ | _]]),
    do: %{title: to_255(flatten_to_string(values))}

  def call(_, "episode", [tag_atom, attr, _])
      when tag_atom in [
             :"itunes:image",
             :"iTunes:image",
             :itunes_image
           ],
      do: %{image_url: to_255(attr[:href]), image_title: to_255(attr[:href])}

  def call(_, "episode", [tag_atom, _, value])
      when tag_atom in [
             :image,
             :imageurl
           ],
      do: parse(%{}, "episode_image", value)

  def call(_, "episode", [:imagetitle, _, [value]]), do: %{image_title: to_255(value)}

  def call(_, "episode_image", [:title, _, _]), do: %{}
  def call(_, "episode_image", [:title, _, [value]]), do: %{image_title: to_255(value)}
  def call(_, "episode_image", [:url, _, []]), do: %{}
  def call(_, "episode_image", [:url, _, [value]]), do: %{image_url: to_255(value)}
  def call(_, "episode_image", [:url, _, [_, value, _]]), do: %{image_url: to_255(value)}
  def call(_, "episode_image", [:link, _, _]), do: %{}
  def call(_, "episode_image", [:description, _, _]), do: %{}
  def call(_, "episode_image", [:width, _, _]), do: %{}
  def call(_, "episode_image", [:height, _, _]), do: %{}

  def call(_, "episode", [:link, _, []]), do: %{}
  def call(_, "episode", [:link, _, [value]]), do: %{link: to_255(value)}
  def call(_, "episode", [:guid, _, [value]]), do: %{guid: to_255(value)}
  def call(_, "episode", [:"itunes:guid", _, [value]]), do: %{guid: to_255(value)}
  def call(_, "episode", [:EpisodeGUID, _, [value]]), do: %{guid: to_255(value)}
  def call(_, "episode", [:id, _, [value]]), do: %{guid: to_255(value)}
  def call(_, "episode", [:guid, _, _]), do: %{}
  def call(_, "episode", [:uniqueid, _, [value]]), do: %{guid: to_255(value)}
  def call(_, "episode", [:uniqueid, _, _]), do: %{}

  def call(_, "episode", [:contentId, _, [value]]), do: %{guid: to_255(value)}

  def call(_, "episode", [:description, _, []]), do: %{}

  def call(_, "episode", [:description, _, values = [_ | _]]),
    do: %{description: scrub(values)}

  def call(_, "episode", [:descrition, _, values = [_ | _]]),
    do: %{description: scrub(values)}

  def call(_, "episode", [:"itunes:description", _, []]), do: %{}

  def call(_, "episode", [:"itunes:description", _, values = [_ | _]]),
    do: %{description: scrub(values)}

  def call(_, "episode", [:"content:encoded", _, []]), do: %{}

  def call(_, "episode", [:"content:encoded", _, values = [_ | _]]),
    do: %{shownotes: scrub(values)}

  def call(_, "episode", [:content, _, []]), do: %{}
  def call(_, "episode", [:content, _, [value]]), do: %{shownotes: scrub(value)}
  def call(_, "episode", [:shownotes, _, []]), do: %{}
  def call(_, "episode", [:shownotes, _, [value]]), do: %{shownotes: scrub(value)}

  def call(_, "episode", [:"itunes:summary", _, []]), do: %{}

  def call(_, "episode", [tag_atom, _, values = [_ | _]])
      when tag_atom in [
             :"itunes:summary",
             :summary,
             :itunes_summary,
             :"atom:summary"
           ],
      do: %{summary: scrub(values)}

  def call(_, "episode", [:summary, _, []]), do: %{}
  def call(_, "episode", [:"atom:summary", _, []]), do: %{}
  def call(_, "episode", [:"itunes:subtitle", _, []]), do: %{}

  def call(_, "episode", [:"itunes:subtitle", _, values = [_ | _]]),
    do: %{subtitle: to_255(flatten_to_string(values))}

  def call(_, "episode", [tag_atom, _, [value]])
      when tag_atom in [
             :subtitle,
             :itunes_subtitle,
             :"itunes:subtitle"
           ],
      do: %{subtitle: to_255(value)}

  def call(_, "episode", [:"itunes:duration", _, []]), do: %{}

  def call(_, "episode", [tag_atom, _, [value]])
      when tag_atom in [
             :"itunes:duration",
             :itunes_duration,
             :duration
           ],
      do: %{duration: value}

  def call(_, "episode", [:duration, _, []]), do: %{}

  def call(_, "episode", [tag_atom, _, [value]])
      when tag_atom in [
             :pubDate,
             :pubdate,
             :"itunes:pubDate",
             :"dc:date",
             :pubDateShort
           ],
      do: %{publishing_date: to_naive_datetime(value)}

  def call(_, "episode", [:pubDate, _, []]) do
    %{publishing_date: now()}
  end

  def call(_, "episode", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "http://podlove.org/deep-link" ->
        %{deep_link: to_255(attr[:href])}

      "payment" ->
        %{payment_link_title: attr[:title], payment_link_url: to_255(attr[:href])}

      "alternate" ->
        %{}

      "http://podlove.org/simple-chapters" ->
        %{}

      "replies" ->
        %{}

      "self" ->
        %{link: to_255(attr[:href])}

      nil ->
        %{link: to_255(attr[:href])}

      # e.g. rel="enclosure" or "related" — used to raise a CaseClauseError
      _ ->
        %{}
    end
  end

  # We expect one episode author
  def call(_, "episode", [:"itunes:author", _, []]), do: %{}

  def call(_, "episode", [tag_atom, _, value])
      when tag_atom in [
             :authors,
             :"iTunes:author",
             :"itunes:author",
             :itunes_author,
             :"googleplay:author",
             :"dc:publisher",
             :"atom:author",
             :Author
           ],
      do: parse(%{}, "episode_author", value)

  def call(_, "episode", [:managingEditor, _, value]), do: parse(%{}, "managing_editor", value)

  # Enclosures a.k.a. Audiofiles
  def call(_, "episode", [:enclosure, attr, _]) do
    enclosure_map = %{
      url: to_255(attr[:url]),
      length: to_255(attr[:length]),
      type: to_255(attr[:type]),
      guid: to_255(attr[:"bitlove:guid"])
    }

    %{enclosures: %{uuid1() => enclosure_map}}
  end

  # Chapters
  def call(_, "episode", [tag_atom, _, value]) when tag_atom in [:"psc:chapters", :chapters] do
    parse(%{}, "chapter", value)
  end

  # We expect several contributors
  def call(map, "tag", [:"atom:contributor", _, value]) do
    parse(map, "contributor", value, uuid1())
  end

  # Episode contributors
  def call(_, "episode", [:"atom:contributor", _, value]) do
    parse(%{}, "episode-contributor", value, uuid1())
  end

  def call(_, "episode", [:"dc:contributor", _, [value]]) do
    %{contributors: %{uuid1() => %{name: to_255(value), uri: to_255(value)}}}
  end

  # podcast:person - https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/tags/person.md
  # channel-level persons (regular hosts/cast); item-level ones (e.g. guests) are handled below
  def call(_, "tag", [:"podcast:person", _attr, []]), do: %{}

  def call(_, "tag", [:"podcast:person", attr, [value | _]]) when is_binary(value) do
    %{contributors: %{uuid1() => person_map(attr, value)}}
  end

  def call(_, "tag", [:"podcast:person", _attr, _value]), do: %{}

  # episode/item-level persons
  def call(_, "episode", [:"podcast:person", _attr, []]), do: %{}

  def call(_, "episode", [:"podcast:person", attr, [value | _]]) when is_binary(value) do
    %{contributors: %{uuid1() => person_map(attr, value)}}
  end

  def call(_, "episode", [:"podcast:person", _attr, _value]), do: %{}

  # Tags we don't parse are skipped silently. Nobody has added a tag to the
  # parser in years, so logging the unknown ones (and keeping long lists of
  # known-and-ignored tags to keep them out of that log) is no longer worth it.
  def call(_, _mode, [_tag, _attr, _value]), do: %{}

  # Now the namespaces:
  def call("chapter", [tag_atom, attr, _]) when tag_atom in [:"psc:chapter", :chapter] do
    %{uuid1() => %{start: attr[:start], title: to_255(attr[:title])}}
  end

  def call("contributor", [:"atom:name", _, [value]]), do: %{name: value}
  def call("contributor", [:"atom:uri", _, [value]]), do: %{uri: value}
  def call("contributor", [:"panoptikum:pid", _, [value]]), do: %{pid: value}

  # An empty <atom:name>/<atom:uri>/<panoptikum:pid> element (self-closing,
  # or opening+closing tag with nothing in between) parses to an empty
  # value list rather than a one-element list — seen live for an empty
  # <atom:uri></atom:uri> under a channel-level <atom:contributor> (crashed
  # with a FunctionClauseError). Same shape already handled below for
  # "episode-contributor"; skip it here too instead of crashing.
  def call("contributor", [:"atom:name", _, []]), do: %{}
  def call("contributor", [:"atom:uri", _, []]), do: %{}
  def call("contributor", [:"panoptikum:pid", _, []]), do: %{}

  def call("episode-contributor", [tag_atom, _, [value]])
      when tag_atom in [
             :"atom:name",
             :"atom:uri"
           ],
      do: %{name: value}

  def call("episode-contributor", [:"atom:uri", _, []]), do: %{}
  def call("episode-contributor", [:"atom:email", _, []]), do: %{}
  def call("episode-contributor", [:"atom:email", _, [value]]), do: %{email: value}
  def call("episode-contributor", [:"panoptikum:pid", _, [value]]), do: %{pid: value}
  def call("episode-contributor", [:"atom:facebook", _, _]), do: %{}

  def call("owner", [:"itunes:name", _, []]), do: %{}

  def call("owner", [tag_atom, _, [value]])
      when tag_atom in [
             :name,
             :"itunes:name",
             :"itunes:author",
             :"itunes:caption"
           ],
      do: %{name: to_255(value)}

  def call("owner", [:"itunes:email", _, []]), do: %{}
  def call("owner", [:"itunes:copyright", _, _]), do: %{}
  def call("owner", [:"itunes:email", _, [value]]), do: %{email: value}
  def call("owner", [:"googleplay:email", _, [value]]), do: %{email: value}
  def call("owner", [:email, _, [value]]), do: %{email: value}
  def call("owner", [:"panoptikum:pid", _, [value]]), do: %{pid: value}

  def call("owner", [tag_atom, _, _])
      when tag_atom in [
             :copyright,
             :"itunes:keywords",
             :"itunes:image",
             :"itunes:explicit",
             :itunes_explicit
           ],
      do: %{}

  def call("author", [:"itunes:name", _, []]), do: %{}
  def call("author", [:"itunes:name", _, [value]]), do: %{name: to_255(value)}
  def call("author", [:"atom:name", _, [value]]), do: %{name: to_255(value)}
  def call("author", [:name, _, [value]]), do: %{name: to_255(value)}
  def call("author", [:"itunes:email", _, []]), do: %{}
  def call("author", [:"itunes:email", _, [value]]), do: %{email: value}
  def call("author", [:"atom:email", _, [value]]), do: %{email: value}
  def call("author", [:"panoptikum:pid", _, [value]]), do: %{pid: value}

  def call("episode_author", [:author, _, value]), do: parse(%{}, "episode_author", value)
  def call("episode_author", [:"itunes:name", _, []]), do: %{}
  def call("episode_author", [:"itunes:name", _, [value]]), do: %{name: to_255(value)}
  def call("episode_author", [:name, _, [value]]), do: %{name: to_255(value)}
  def call("episode_author", [:"atom:name", _, [value]]), do: %{name: to_255(value)}
  def call("episode_author", [:a, _, [value]]), do: %{name: to_255(value)}
  def call("episode_author", [:"itunes:email", _, []]), do: %{}
  def call("episode_author", [:"itunes:email", _, [value]]), do: %{email: value}
  def call("episode_author", [:"atom:email", _, [value]]), do: %{email: value}
  def call("episode_author", [:"panoptikum:pid", _, [value]]), do: %{pid: value}

  def call("episode_author", [tag_atom, _, _]) when tag_atom in [:avatar], do: %{}

  # Catch-all for the role-based contexts above (contributor,
  # episode-contributor, owner, author, episode_author, chapter) plus
  # "managing_editor" (podcast-level managingEditor/owner/author fields,
  # see Iterator.parse/4's :podcast_contributor clause — it had *no*
  # clauses at all until now). These fields are normally plain text, so
  # Analyzer.call/2 for them only runs when the raw content actually
  # contains nested markup instead — e.g. Cloudflare's email-obfuscation
  # <a class="__cf_email__" data-cfemail="...">[email protected]</a>
  # snippet showing up inside <managingEditor> (crashed live with a
  # FunctionClauseError). Unlike episode_author's specific :a clause
  # above, don't try to salvage a name from unrecognized markup — for
  # most of these (that Cloudflare placeholder text included) there's
  # nothing meaningful to keep. Skipped silently, like the call/3
  # catch-all above.
  def call(_mode, [_tag, _attr, _value]), do: %{}

  defp person_map(attr, value) do
    %{name: to_255(value), role: normalize_role(attr[:role])}
    |> maybe_put(:uri, to_255(attr[:href]))
    |> maybe_put(:image_url, to_255(attr[:img]))
  end

  defp normalize_role(nil), do: "host"
  defp normalize_role(role), do: role |> to_string() |> String.trim() |> String.downcase()

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @atom_link_href_fields %{
    "next" => :next_page_url,
    "prev" => :prev_page_url,
    "prev-archive" => :prev_page_url,
    "previous" => :prev_page_url,
    "first" => :first_page_url,
    "last" => :last_page_url,
    "hub" => :hub_link_url
  }

  defp parse_atom_link(attr) do
    rel = attr[:rel]

    cond do
      rel in ["self", "current"] ->
        %{feed: %{self_link_title: attr[:title], self_link_url: attr[:href]}}

      field = @atom_link_href_fields[rel] ->
        %{feed: %{field => attr[:href]}}

      rel == "alternate" ->
        %{feed: %{alternate_feeds: %{uuid1() => %{title: attr[:title], url: attr[:href]}}}}

      rel == "payment" ->
        %{payment_link_title: attr[:title], payment_link_url: to_255(attr[:href])}

      true ->
        %{}
    end
  end
end
