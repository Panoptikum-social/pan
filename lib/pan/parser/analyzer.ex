defmodule Pan.Parser.Analyzer do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Helpers , as: H
  require Logger

  defdelegate dm(left, right), to: Pan.Parser.Helpers, as: :deep_merge

#wrappers to dive into
  def call(map, "tag", [:rss,     _, value]), do: Iterator.parse(map, "tag", value)
  def call(map, "tag", [:channel, _, value]), do: Iterator.parse(map, "tag", value)


# simple tags to include in podcast
  def call(_, "tag", [:title,             _, []]), do: %{}
  def call(_, "tag", [:title,             _, [value]]), do: %{title: value}
  def call(_, "tag", [:"itunes:summary",  _, []]),      do: %{}
  def call(_, "tag", [:"itunes:summary",  _, [value | _]]), do: %{summary: value}
  def call(_, "tag", [:link,              _, []]), do: %{}
  def call(_, "tag", [:link,              _, [value]]), do: %{website: value}

  def call(_, "tag", [:"itunes:new-feed-url", _, []]), do: %{}
  def call(_, "tag", [:"new-feed-url", _, [value]]), do: %{new_feed_url: value}
  def call(_, "tag", [:"itunes:new-feed-url", _, [value]]), do: %{new_feed_url: value}

  def call(_, "tag", [tag_atom, _, [value]]) when tag_atom in [
    :"itunes:explicit", :"iTunes:explicit", :explicit
  ], do: %{explicit: H.boolify(value)}

  def call(_, "tag", [:lastBuildDate,     _, [value]]) do
    %{last_build_date: H.to_naive_datetime(value)}
  end
  def call(_, "tag", [:"dc:date", _, [value]]) do
    %{last_build_date: H.to_naive_datetime(value)}
  end
  def call(_, "tag", [:pubdate, _, []]), do: %{}
  def call(_, "tag", [:pubDate, _, []]), do: %{}
  def call(_, "tag", [:pubdate, _, [value]]), do: %{last_build_date: H.to_naive_datetime(value)}
  def call(_, "tag", [:pubDate, _, [value]]), do: %{last_build_date: H.to_naive_datetime(value)}
  def call(_, "tag", [:lastPubDate, _, [value]]), do: %{last_build_date: H.to_naive_datetime(value)}

# image with fallback to itunes:image
  def call(_, "tag", [:image, _, value]), do: Iterator.parse(%{}, "image", value)
  def call(_, "image", [:title, _, _]), do: %{}
  def call(_, "image", [:title, _, [value]]), do: %{image_title: H.to_255(value)}
  def call(_, "image", [:url,   _, []]), do: %{}
  def call(_, "image", [:url,   _, [value]]), do: %{image_url: H.to_255(value)}
  def call(_, "image", [:link,        _, _]), do: %{}
  def call(_, "image", [:description, _, _]), do: %{}
  def call(_, "image", [:width,       _, _]), do: %{}
  def call(_, "image", [:height,      _, _]), do: %{}

  def call(map, "image", [tag_atom, attr, _]) when tag_atom in [
    :"itunes:image", :"iTunes:image"
  ] do
    if map[:image_url], do: map,
                        else: %{image_url: H.to_255(attr[:href]),
                                image_title: H.to_255(attr[:href])}
  end

  def call(map, "tag", [tag_atom, attr, _]) when tag_atom in [
    :"itunes:image", :"iTunes:image"
  ] do
    if map[:image_url], do: map,
                        else: %{image_url: H.to_255(attr[:href]),
                                image_title: H.to_255(attr[:href])}
  end

  def call(map, "tag", [tag_atom, _, [value]]) when tag_atom in [
    :"itunes:image", :"iTunes:image"
  ] do
    if map[:image_url], do: map,
                        else: %{image_url: H.to_255(value)}
  end


  def call(_, "tag", [tag_atom, _, []]) when tag_atom in [:description, :"itunes:subtitle"] , do: %{}
  def call(_, "tag", [:description, _, [value | _]]), do: %{description: value}
  def call(_, "tag", [:"itunes:description", _, [value | _]]), do: %{description: value}

  def call(map, "tag", [tag_atom, _, [value]]) when tag_atom in [
    :"itunes:subtitle", :"iTunes:subtitle"
  ] do
    if map[:description], do: %{},
                          else: %{description: value}
  end


# simple tags to include into nested structure
  def call(_, "tag", [:generator, _, []]), do: %{}
  def call(_, "tag", [:generator, _, [value]]), do: %{feed: %{feed_generator: value}}


# the links are a mixture of the two above
  def call(_, "tag", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "self"      -> %{feed: %{self_link_title: attr[:title],
                            self_link_url: attr[:href]}}
      "current"   -> %{feed: %{self_link_title: attr[:title],
                            self_link_url: attr[:href]}}
      "next"      -> %{feed: %{next_page_url: attr[:href]}}
      "prev"      -> %{feed: %{prev_page_url: attr[:href]}}
      "prev-archive" -> %{feed: %{prev_page_url: attr[:href]}}
      "previous"  -> %{feed: %{prev_page_url: attr[:href]}}
      "first"     -> %{feed: %{first_page_url: attr[:href]}}
      "last"      -> %{feed: %{last_page_url: attr[:href]}}
      "hub"       -> %{feed: %{hub_link_url: attr[:href]}}
      "search"    -> %{}
      "related"   -> %{}
      "via"       -> %{}
      nil         -> %{}
      "alternate" ->
        alternate_feed_map = %{UUID.uuid1() => %{title: attr[:title], url: attr[:href]}}
        %{feed: %{alternate_feeds: alternate_feed_map}}
      "payment" -> %{payment_link_title: attr[:title],
                     payment_link_url: H.to_255(attr[:href])}
    end
  end

  def call(_, "tag", [:"rawvoice:donate", attr, [value]]), do: %{payment_link_title: value,
                                                                 payment_link_url: attr[:href]}
  def call(_, "tag", [:"rawvoice:donate", attr, []]), do: %{payment_link_title: attr[:href],
                                                            payment_link_url: attr[:href]}


  def call(_, "tag", [:"atom10:link", attr, _]) do
    case attr[:rel] do
      "self"  -> %{feed: %{self_link_title: attr[:title],
                           self_link_url:   attr[:href]}}
      "hub" -> %{}
    end
  end


# tags to ignore
  def call(map, "tag", [tag_atom, _, _]) when tag_atom in [
    :"feedpress:locale", :"fyyd:verify", :"itunes:block", :"itunes:keywords", :"media:thumbnail",
    :"media:keywords", :"media:category", :category, :site, :docs, :"feedburner:info", :logo, :div,
    :"media:credit", :"media:copyright", :"media:rating", :"media:description", :copyright, :id,
    :"feedburner:feedFlare", :"geo:lat", :"geo:long", :"creativeCommons:license", :"clipper:id",
    :"feedburner:emailServiceId", :"feedburner:feedburnerHostname", :"dc:subject",
    :"sy:updatePeriod", :"sy:updateFrequency", :"wfw:commentRss", :"rawvoice:subscribe", :updated,
    :webMaster, :ttl, :"googleplay:description", :"googleplay:email", :pic,
    :"googleplay:category", :"rawvoice:rating", :"rawvoice:location", :"rawvoice:frequency", :block,
    :"ppg:seriesDetails", :"ppg:systemRef", :"ppg:network", :cloud, :"googleplay:image", :style,
    :"googleplay:author", :"googleplay:explicit", :feed, :webmaster, :ilink, :ffmpeg, :domain,
    :lame, :broadcastlimit, :"itunes:link", :"channelExportDir", :"atom:id", :"sy:updateBase",
    :"openSearch:totalResults", :"openSearch:startIndex", :"openSearch:itemsPerPage", :"html",
    :"ard:programInformation", :"dc:creator", :"itunes:complete", :feedType,
    :changefreq, :"dc:title", :"feedburner:browserFriendly", :itunesowner, :textInput, :refURL,
    :"podcastRF:originStation", :"itunes:explicit", :meta, :"dc:rights", :skipDays, :a, :p, :br, :b,
    :"sc:totalAvailable", :skipHours, :keywords, :script, :"googleplay:block", :guid, :odToken,
    :"itunes:name", :"amp:logo", :"itunes:catago", :"xhtml:meta", :"avms:id",
    :"blogChannel:blogRoll", :"blogChannel:blink", :"thespringbox:skin", :"admin:generatorAgent",
    :"feedpress:podcastId", :summary, :rating, :Category, :"amp:background", :"amp:banner",
    :"amp:halfBanner", :"amp:networkLogo", :"amp:networkSmallLogo", :"amp:networkHalfBanner",
    :"amp:networkBackground", :"amp:networkWebsite", :artwork, :"amp:showFeaturedLogo", :feedcss,
    :"amp:tracking", :"itunes:subitle", :"feedpress:newsletterId", :"blogger:adultContent",
    :frequenceMiseAJour, :EmissionParlee, :"ionofm:thumbnail", :EmissionMusical, :audioExist,
    :videoExist, :nomTypePodcast, :nomDocCategorie, :nomURLPodCast, :leRSS, :leRSSitunes, :license,
    :lastbuilddate, :"sy:updateperiod", :"sy:updatefrequency", :"a10:link", :lastBuildDate,
    :"atom:updated", :"itunes:podcastskeywords", :"aan:channel_id", :"aan:feedback", :enclosure,
    :"aan:iTunes_id", :"aan:publicsearch", :"aan:isitunes", :"podextra:filtered", :"webfeeds:logo",
    :"webfeeds:accentColor", :"volomedia:ga_id", :"dc:coverage", :"itunes:image-small", :xmlUrl,
    :"awesound:lastCached", :"admin:errorReportsTo", :"cbs:id", :"itunes:new_feed_url", :generation,
    :companyLogo, :"itunes:type", :convertLineBreaks, :"content:encoded", :subtitle, :itunes,
    :"c9:totalResults", :"c9:pageCount", :"c9:pageSize", :"castfire:total", :"castfire:sh_id",
    :"ionofm:coverart", :"itunes:subcategory", :"icbm:latitude", :"icbm:longitude", :"yt:channelId",
    :"a10:author", :"a10:contributor", :"a10:id", :"itunes:publisher", :"webfeeds:cover",
    :"webfeeds:icon", :"webfeeds:related", :"webfeeds:analytics", :"dc:publisher", :"desription",
    :"collectiontype", :"pentonplayer:channelAds", :"all-js-function", :"media:title", :"media:text",
    :fullsummary, :"itunes:subtitle", :"nrk:url", :"nrk:urlTitle"
  ], do: map

  def call(_, "episode", [tag_atom, _, _]) when tag_atom in [
    :"googleplay:description", :"googleplay:image", :"googleplay:explicit", :"googleplay:block",
    :"frn:id", :"frn:title", :"frn:language", :"frn:art", :"frn:radio", :"frn:serie", :"frn:laenge",
    :"frn:licence", :"frn:last_update", :"itunes:keywords", :"post-id", :author, :"itunes:explicit",
    :category, :"dc:creator", :comments, :"feedburner:origLink", :"dc:modifieddate",
    :"feedburner:origEnclosureLink", :"wfw:commentRss", :"slash:comments", :"itunes:block", :meta,
    :"itunes:order", :"ppg:canonical", :"cba:productionDate", :"cba:broadcastDate", :payment, :url,
    :"cba:containsCopyright", :"media:thumbnail", :source, :"media:description", :programid,
    :poddid, :"dcterms:modified", :"dcterms:created", :toPubDate, :audioId, :"atom:updated", :img,
    :"thr:total", :"ard:visibility", :"series:name", :"rawvoice:poster", :"georss:point", :length,
    :"copyright", :"ard:programInformation", :"sc:chapters", :"xhtml:body", :"itunesu:category",
    :"wfw:content", :"wfw:comment", :"creativeCommons:license", :itemDate, :"ddn:id",
    :"media:keywords", :"media:rights", :"ppg:enclosureLegacy", :"ppg:enclosureSecure", :timestamp,
    :"podcastRF:businessReference", :"podcastRF:magnetothequeID", :"podcastRF:stepID", :explicit,
    :"media:title", :"media:credit", :"dc:subject", :"dc:identifier", :"georss:featurename", :tags,
    :"georss:box", :"gd:extendedProperty", :"media:content", :"rawvoice:metamark", :"media:player",
    :"itunes:category", :"fyyd:episodeID", :"fyyd:podcastID", :"fyyd:origPubdate", :"geo:lat",
    :"geo:long", :"rawvoice:isHD", :"podcast:type", :"podcast:description", :"media:rating", :style,
    :"podfm:nodownload", :"podfm:downloadCount", :script, :"rte-days", :"rawvoice:embed", :showImage,
    :"lastBuildDate", :"merriam:shortdef", :"dc:title", :div, :"rawvoice:webm", :"subTitleLink",
    :"app:edited", :"media:text", :"ecc:description", :guide, :"dc:description", :"itunes:keyword",
    :"media:group", :"rawvoice:donate", :"podcast:title", :"media:copyright", :"pingback:server",
    :"itunes:length", :"podcast:name", :"blip:user", :"username", :"dc:copyright", :"dc:type",
    :"pingback:target", :"trackback:ping", :filename, :"blip:userid", :"blip:safeusername", :mobile,
    :"blip:showpath", :"blip:show", :"blip:showpage", :"blip:picture", :"blip:posts_id",
    :"blip:item_id", :"blip:item_type", :"blip:rating", :"blip:datestamp", :"blip:language", :tags,
    :"blip:adChannel", :"blip:categories", :"blip:license", :"blip:puredescription", :"dc:rights",
    :"blip:thumbnail_src", :"blip:", :"blip:embedUrl", :"blip:embedLookup", :"blip:runtime", :draft,
    :"blip:adminRating", :"blip:core_value", :"blip:core", :"blip:recommendable", :"avms:id", :hq,
    :"blip:recommendations", :"yv:adInfo", :"blip:smallThumbnail", :"clipper:id", :"a10:link",
    :"uzhfeeds:image", :"amp:banner", :"itunes:isClosedCaptioned", :"blip:poster_image", :showThumb,
    :"georss:where", :"itunes:subitle", :"media:category", :"geourl:latitude", :"geourl:longitude",
    :"icbm:latitude", :"icbm:longitude", :"itunes:owner", :"jwplayer:image", :"flickr:date_taken",
    :"dc:date.Taken", :title_in_language, :foto_207, :"ddn:episode_id", :lead, :date, :sendung,
    :"ddn:special", :"ddn:expires", :"grtv:image", :showIcon, :youtubeID, :group, :"nprml:parent",
    :"blip:youtube_category", :"blip:distributions_info", :"media:adult", :"jwplayer:file", :owner,
    :"jwplayer:duration", :"ionofm:thumbnail", :"blip:is_premium", :"blip:channel_name", :keyword,
    :"blip:channel_list", :"blip:betaUser", :dureeReference, :"wfw:commentrss", :"ez:id", :"cfi:id",
    :"digicast:image", :"digicast:website", :"dc:language", :"atom:published", :"cfi:read", :pic,
    :"cfi:downloadurl", :"cfi:lastdownloadtime", :"cba:broadcast", :"aan:item_id", :"aan:segments",
    :"aan:cme", :keywords, :"itunes:link", :"podextra:humandate", :"podextra:player", :comment,
    :"cba:duration", :"cba:attachmentID", :"im:image", :"episode_mp3", :"jwplayer:talkId", :artist,
    :"aidsgov:transcript", :"foto_428", :"podcast:brandStory", :"thr:in-reply-to", :"media:hash",
    :"posterous:author", :"companyLogo", :"coverimage", :"media:thumb", :"podcast:spotlight", :tag,
    :"itunes:name", :"itunes:episode", :"itunes:episodeType", :"itunes:season", :"georss:elev", :br,
    :"podcast:category", :podcastimge1, :podcastimge2, :"itunes:type", :hq_filename, :hq_filetype,
    :stream, :"itunes:email", :indTag, :"app:control", :size, :"itunes:isCloseCaptioned", :guid2,
    :updated, :published, :subtitle, :titleApp, :topTitleApp, :"ionofm:coverart", :p, :body,
    :"itunes:subtitel", :"includedComments:comment-collection", :"dcterms:valid", :"sr:programid",
    :"sr:poddid", :itunes, :"media:enclosure", :"yt:videoId", :"yt:channelId", :durationapp,
    :categorie, :"photo:imgsrc", :expiryTime, :"a10:updated", :"a10:content", :"a10:author",
    :"dc:source",  :"meta:broadcastDate", :"aan:quiz_link", :"dc:modified", :"media:restriction",
    :"usenix:author", :"wfw:commentRSS", :"podcast:attachment", :"post-thumbnail", :bitrate,
    :"rcr:profile", :"rcr:cover", :postthumbnail, :fxexcerpt, :"itunes:artwork", :"descriptionApp",
    :"pentonplayer:playerlink", :"pentonplayer:downloadlink", :"pentonplayer:adTimes", :"cat5tv:id",
    :"epidsode-js-function", :"cat5tv:number", :"cat5tv:slug", :"cat5tv:title", :"cat5tv:year",
    :"cat5tv:season", :"cat5tv:genre", :"cat5tv:description", :"cat5tv:thumbnail", :"castfire:sh_id",
    :"castfire:show_id", :"castfire:network", :"castfire:content_producer", :"castfire:channel",
    :"castfire:date", :"castfire:filename", :"castfire:categories", :fullsummary, :newsid,
    :"lj:replycount", :"xerosocial", :media, :language
  ], do: %{}


  def call(_, "image", [tag_atom, _, _]) when tag_atom in [:guid, :meta, :"content:encoded"], do: %{}


# We expect several language tags
  def call(_, "tag", [:language, _, []]), do: %{}
  def call(_, "tag", [tag_atom, _, [value]]) when tag_atom in [:language, :"dc:language"] do
    %{languages: %{UUID.uuid1() => %{shortcode: value}}}
  end

# We expect one owner
  def call(_, "tag", [tag_atom, _, value]) when tag_atom in [
    :"itunes:owner", :owner, :"itunes:email"
  ], do: Iterator.parse(%{}, :podcast_contributor, "owner", value)

# We expect one podcast author
  def call(_, "tag", [:"itunes:author",        _, []]), do: %{}
  def call(_, "tag", [tag_atom, _, value]) when tag_atom in [
    :"itunes:author", :"atom:author", :author, :"googleplay:author", :artist
  ], do: Iterator.parse(%{}, :podcast_contributor, "author", value)


  def call(_, "tag", [tag_atom, _, value]) when tag_atom in [
    :"managingEditor", :managingeditor, :"manageEditor"
  ] do
    Iterator.parse(%{}, :podcast_contributor, "managing_editor", value)
  end

# Parsing categories infintely deep
  def call(_, "tag", [:"itunes:category", attr, []]) do
    %{categories: %{UUID.uuid1() => %{title: attr[:text], parent: nil}}}
  end
  def call(_, "tag", [:"itunes:category", [], [value]]) do
    %{categories: %{UUID.uuid1() => %{title: value, parent: nil}}}
  end
  def call(_, "tag", [:"itunes:category", attr, value]) do
    Iterator.parse(%{categories: %{UUID.uuid1() => %{title: attr[:text], parent: nil}}}, "category", value, attr[:text])
  end

  def call("category", [:"itunes:category", attr, []], parent_title) do
    %{categories: %{UUID.uuid1() => %{title: attr[:text], parent: parent_title}}}
  end

  def call("category", [:"itunes:category", attr, value], parent_title) do
    Iterator.parse(%{categories: %{UUID.uuid1() => %{title: attr[:text], parent: parent_title}}}, "category", value, attr[:text])
  end


# Episodes
  def call(map, "tag",     [:item, _, value]), do: Iterator.parse(map, "episode", value, UUID.uuid1())
  def call(map, "episode", [:item, _, value]), do: Iterator.parse(map, "episode", value, UUID.uuid1())

  def call(_, "episode", [:title, _, []]), do: %{title: "emtpy"}
  def call(_, "episode", [:title, _, [value | _]]), do: %{title: H.to_255(value)}
  def call(_, "episode", [:"itunes:title", _, []]), do: %{title: "emtpy"}
  def call(_, "episode", [:"itunes:title", _, [value | _]]), do: %{title: H.to_255(value)}

  def call(_, "episode", [tag_atom, attr, _]) when tag_atom in [
    :"itunes:image", :"iTunes:image", :"itunes_image"
  ], do: %{image_url: H.to_255(attr[:href]), image_title: H.to_255(attr[:href])}

  def call(_, "episode", [tag_atom, _, value]) when tag_atom in [
    :image, :imageurl], do: Iterator.parse(%{}, "episode_image", value)
  def call(_, "episode", [:imagetitle, _, [value]]), do: %{image_title: H.to_255(value)}

  def call(_, "episode_image", [:title, _, _]), do: %{}
  def call(_, "episode_image", [:title, _, [value]]), do: %{image_title: H.to_255(value)}
  def call(_, "episode_image", [:url,   _, []]), do: %{}
  def call(_, "episode_image", [:url,   _, [value]]), do: %{image_url: H.to_255(value)}
  def call(_, "episode_image", [:link,        _, _]), do: %{}
  def call(_, "episode_image", [:description, _, _]), do: %{}
  def call(_, "episode_image", [:width,       _, _]), do: %{}
  def call(_, "episode_image", [:height,      _, _]), do: %{}


  def call(_, "episode", [:link, _, []]), do: %{}
  def call(_, "episode", [:link, _, [value]]), do: %{link: H.to_255(value)}
  def call(_, "episode", [:guid, _, [value]]), do: %{guid: H.to_255(value)}
  def call(_, "episode", [:"itunes:guid", _, [value]]), do: %{guid: H.to_255(value)}
  def call(_, "episode", [:EpisodeGUID, _, [value]]), do: %{guid: H.to_255(value)}
  def call(_, "episode", [:id, _, [value]]), do: %{guid: H.to_255(value)}
  def call(_, "episode", [:guid, _, _]), do: %{}
  def call(_, "episode", [:uniqueid, _, [value]]), do: %{guid: H.to_255(value)}
  def call(_, "episode", [:uniqueid, _, _]), do: %{}

  def call(_, "episode", [:contentId, _, [value]]), do: %{guid: H.to_255(value)}

  def call(_, "episode", [:description, _, []]), do: %{}
  def call(_, "episode", [:description, _, [value | _]]), do: %{description: HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:descrition, _, [value | _]]), do: %{description: HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:"itunes:description", _, []]), do: %{}
  def call(_, "episode", [:"itunes:description", _, [value | _]]), do: %{description: HtmlSanitizeEx2.basic_html_reduced(value)}

  def call(_, "episode", [:"content:encoded", _, []]), do: %{}
  def call(_, "episode", [:"content:encoded", _, [value]]), do: %{shownotes: HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:content, _, []]), do: %{}
  def call(_, "episode", [:content, _, [value]]), do: %{shownotes: HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:shownotes, _, []]), do: %{}
  def call(_, "episode", [:shownotes, _, [value]]), do: %{shownotes: HtmlSanitizeEx2.basic_html_reduced(value)}

  def call(_, "episode", [:"itunes:summary",  _, []]), do: %{}
  def call(_, "episode", [:"itunes:summary",  _, [value | _]]) when is_map(value) do
    %{summary: HtmlSanitizeEx2.basic_html_reduced(List.first(value[:value]))}
  end
  def call(_, "episode", [:"itunes:summary",  _, [value | _]]), do: %{summary: HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:summary,           _, [value]]), do: %{summary: HtmlSanitizeEx2.basic_html_reduced(value)}
  def call(_, "episode", [:"atom:summary",  _, []]), do: %{}
  def call(_, "episode", [:"atom:summary",  _, [value | _]]), do: %{summary: HtmlSanitizeEx2.basic_html_reduced(value)}

  def call(_, "episode", [:"itunes:subtitle", _, []]), do: %{}
  def call(_, "episode", [:"itunes:subtitle", _, [value]]), do: %{subtitle: H.to_255(value)}
  def call(_, "episode", [:subtitle,          _, [value]]), do: %{subtitle: H.to_255(value)}
  def call(_, "episode", [:"itunes:subtitle", _, [value | _]]), do: %{subtitle: H.to_255(value)}

  def call(_, "episode", [:"itunes:duration", _, []]), do: %{}
  def call(_, "episode", [:"itunes:duration", _, [value]]), do: %{duration: value}
  def call(_, "episode", [:duration, _, []]), do: %{}
  def call(_, "episode", [:duration, _, [value]]), do: %{duration: value}

  def call(_, "episode", [tag_atom, _, [value]]) when tag_atom in [
      :pubDate, :pubdate, :"itunes:pubDate", :"dc:date", :pubDateShort
    ], do: %{publishing_date: H.to_naive_datetime(value)}

  def call(_, "episode", [:pubDate, _, []]) do
    %{publishing_date: Timex.now()}
  end

  def call(_, "episode", [:"atom:link", attr, _]) do
    case attr[:rel] do
      "http://podlove.org/deep-link" ->
        %{deep_link: H.to_255(attr[:href])}
      "payment" ->
        %{payment_link_title: attr[:title],
          payment_link_url: H.to_255(attr[:href])}
      "alternate" ->
        %{}
      "http://podlove.org/simple-chapters" ->
        %{}
      "replies" ->
        %{}
      "self" ->
        %{link: H.to_255(attr[:href])}
      nil ->
        %{link: H.to_255(attr[:href])}
    end
  end


# We expect one episode author
  def call(_, "episode", [:"itunes:author",     _, []]), do: %{}
  def call(_, "episode", [:authors,             _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call(_, "episode", [:"iTunes:author",     _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call(_, "episode", [:"itunes:author",     _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call(_, "episode", [:"googleplay:author", _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call(_, "episode", [:"dc:publisher",      _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call(_, "episode", [:"atom:author",       _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call(_, "episode", [:Author,              _, value]), do: Iterator.parse(%{}, "episode_author", value)


# Enclosures a.k.a. Audiofiles
  def call(_, "episode", [:enclosure, attr, _]) do
    enclosure_map = %{url:    H.to_255(attr[:url]),
                      length: H.to_255(attr[:length]),
                      type:   H.to_255(attr[:type]),
                      guid:   H.to_255(attr[:"bitlove:guid"])}
    %{enclosures: %{UUID.uuid1() => enclosure_map}}
  end


# Chapters
  def call(_, "episode", [tag_atom, _, value]) when tag_atom in [:"psc:chapters", :chapters] do
    Iterator.parse(%{}, "chapter", value)
  end


# We expect several contributors
  def call(map, "tag", [:"atom:contributor", _, value]) do
    Iterator.parse(map, "contributor", value, UUID.uuid1())
  end


# Episode contributors
  def call(_, "episode", [:"atom:contributor", _, value]) do
    Iterator.parse(%{}, "episode-contributor", value, UUID.uuid1())
  end
  def call(_, "episode", [:"dc:contributor", _, [value]]) do
    %{contributors: %{UUID.uuid1() => %{name: value, uri: value}}}
  end


# Show debugging information for unknown tags on console
  def call(_, mode, [tag, attr, value]) do
    Logger.warn "=== Tag unknown: ==="
    Logger.warn "Mode: #{mode}"
    Logger.warn ~s(Tag: :"#{tag}")
    Logger.warn "Attr: #{inspect attr}"
    Logger.warn "Value: #{inspect value}"
    {:error, "tag unknown"}
  end


# Now the namespaces:
  def call("chapter", [tag_atom, attr, _]) when tag_atom in [:"psc:chapter", :chapter] do
    %{UUID.uuid1() => %{start: attr[:start], title: H.to_255(attr[:title])}}
  end

  def call("contributor", [:"atom:name",       _, [value]]), do: %{name: value}
  def call("contributor", [:"atom:uri",        _, [value]]), do: %{uri:  value}
  def call("contributor", [:"panoptikum:pid",  _, [value]]), do: %{pid:  value}


  def call("episode-contributor", [:"atom:name",       _, [value]]), do: %{name:  value}
  def call("episode-contributor", [:"atom:uri",        _, []]), do: %{}
  def call("episode-contributor", [:"atom:uri",        _, [value]]), do: %{uri:   value}
  def call("episode-contributor", [:"atom:email",      _, []]), do: %{}
  def call("episode-contributor", [:"atom:email",      _, [value]]), do: %{email: value}
  def call("episode-contributor", [:"panoptikum:pid",  _, [value]]), do: %{pid:   value}


  def call("owner", [:"itunes:name",     _, []]), do: %{}
  def call("owner", [tag_atom, _, [value]]) when tag_atom in [
    :name, :"itunes:name", :"itunes:author", :"itunes:caption"
  ], do: %{name: H.to_255(value)}
  def call("owner", [:"itunes:email",    _, []]), do: %{}
  def call("owner", [:"itunes:email",    _, [value]]), do: %{email: value}
  def call("owner", [:"googleplay:email", _, [value]]), do: %{email: value}
  def call("owner", [:email,             _, [value]]), do: %{email: value}
  def call("owner", [:"panoptikum:pid",  _, [value]]), do: %{pid: value}
  def call("owner", [tag_atom, _, _]) when tag_atom in [
    :copyright, :"itunes:keywords", :"itunes:image", :"itunes:explicit"
  ], do: %{}


  def call("author", [:"itunes:name",     _, []]), do: %{}
  def call("author", [:"itunes:name",     _, [value]]), do: %{name: H.to_255(value)}
  def call("author", [:"atom:name",       _, [value]]), do: %{name: H.to_255(value)}
  def call("author", [:"name",            _, [value]]), do: %{name: H.to_255(value)}
  def call("author", [:"itunes:email",    _, []]), do: %{}
  def call("author", [:"itunes:email",    _, [value]]), do: %{email: value}
  def call("author", [:"atom:email",      _, [value]]), do: %{email: value}
  def call("author", [:"panoptikum:pid",  _, [value]]), do: %{pid: value}


  def call("episode_author", [:author,            _, value]), do: Iterator.parse(%{}, "episode_author", value)
  def call("episode_author", [:"itunes:name",     _, []]), do: %{}
  def call("episode_author", [:"itunes:name",     _, [value]]), do: %{name: H.to_255(value)}
  def call("episode_author", [:name,              _, [value]]), do: %{name: H.to_255(value)}
  def call("episode_author", [:"atom:name",       _, [value]]), do: %{name: H.to_255(value)}
  def call("episode_author", [:a,                 _, [value]]), do: %{name: H.to_255(value)}
  def call("episode_author", [:"itunes:email",    _, []]), do: %{}
  def call("episode_author", [:"itunes:email",    _, [value]]), do: %{email: value}
  def call("episode_author", [:"atom:email",      _, [value]]), do: %{email: value}
  def call("episode_author", [:"panoptikum:pid",  _, [value]]), do: %{pid: value}

  def call("episode_author", [tag_atom, _, _]) when tag_atom in [:avatar], do: %{}
end
