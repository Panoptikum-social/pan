defmodule Pan.Parser do

  def parse do
    import SweetXml

    {:ok, xml} = File.read "materials/freakshow.xml.orig"

    title = xml |> xpath(~x"//channel/title/text()"s)
    website = xml |> xpath(~x"//channel/link/text()"s)
    description = xml |> xpath(~x"//channel/description/text()"s)
    language = xml |> xpath(~x"//channel/language/text()"s)
    summary = xml |> xpath(~x"//channel/itunes:summary/text()"s)

    image = xml
            |> xpath(~x"//channel/image",
                     title: ~x"./title/text()"s,
                     url: ~x"./url/text()"s)

    last_build_date = xml |> xpath(~x"//channel/lastBuildDate/text()"s)
                      |> Timex.parse("{RFC1123}")

    self_link = xml
                |> xpath(~x"//channel/atom:link[@rel='self']",
                         title: ~x"./@title"s,
                         href: ~x"./@href"s)

    next_page_href =  xml |> xpath(~x"//channel/atom:link[@rel='next']//@href"s)
    prev_page_href =  xml |> xpath(~x"//channel/atom:link[@rel='prev']//@href"s)
    first_page_href = xml |> xpath(~x"//channel/atom:link[@rel='first']//@href"s)
    last_page_href =  xml |> xpath(~x"//channel/atom:link[@rel='last']//@href"s)

    hub_link_href =   xml |> xpath(~x"//channel/atom:link[@rel='hub']//@href"s)

    payment_link = xml
                   |> xpath(~x"//channel/atom:link[@rel='payment']"l,
                            title: ~x"./@title"s,
                            href: ~x"./@href"s)

    itunes_owner = xml
                   |> xpath(~x"//channel/itunes:owner",
                            name: ~x"./itunes:name/text()"s,
                            email: ~x"./itunes:email/text()"s)

    itunes_author = xml |> xpath(~x"//channel/itunes:author/text()"s)
    itunes_explicit = xml |> xpath(~x"//channel/itunes:explicit/text()"s)

    feed_generator =  xml |> xpath(~x"//channel/generator/text()"s)

    alternate_links = xml
                      |> xpath(~x"//channel/atom:link[@rel='alternate']"l,
                      title: ~x"./@title"s,
                      href: ~x"./@href"s)

    contributer = xml
                  |> xpath(~x"//channel/atom:contributor"l,
                           name: ~x"./atom:name/text()"s,
                           uri: ~x"./atom:uri/text()"s)

    categories = xml
                 |> xpath(~x"//channel/itunes:category"l,
                          title: ~x"./@text"s,
                          subtitle: ~x"./itunes:category/@text"s)


    episodes =  xml
                |> xpath(~x"//channel/item"l)
                |> Enum.map fn (episode) ->
                     %{
                       title: episode
                              |> xpath(~x"./title/text()"s),
                       link:  episode
                              |> xpath(~x"./link/text()"s),
                       publishing_date: episode
                                        |> xpath(~x"./pubDate/text()"s)
                                        |> Timex.parse("{RFC1123}"),
                       guid: episode
                             |> xpath(~x"./guid/text()"s),
                       description: episode
                                    |> xpath(~x"./description/text()"s),
                       shownotes: episode
                                  |> xpath(~x"./content:encoded/text()"s),
                       payment_link: episode
                                     |> xpath(~x"./atom:link[@rel='payment']",
                                              title: ~x"./@title"s,
                                              href: ~x"./@href"s),
                       contributors:  episode
                                      |> xpath(~x"atom:contributor"l,
                                               name: ~x"./atom:name/text()"s,
                                               uri: ~x"./atom:uri/text()"s),
                       chapters: episode
                                 |> xpath(~x"psc:chapters/psc:chapter"l,
                                          start: ~x"./@start"s,
                                          title: ~x"./@title"s),
                       deep_link: episode
                                  |> xpath(~x"./atom:link[@rel='http://podlove.org/deep-link']/@href"s),
                       enclosure: episode
                                  |> xpath(~x"./enclosure"l,
                                           url: ~x"./@url"s,
                                           length: ~x"./@length"s,
                                           type: ~x"./@type"s,
                                           guid: ~x"./@bitlove:guid"s),
                       duration: episode
                                 |> xpath(~x"./itunes:duration/text()"s),
                       author: episode
                               |> xpath(~x"./itunes:author/text()"s),
                       subtitle: episode
                                 |> xpath(~x"./itunes:subtitle/text()"s),
                       summary: episode
                                |> xpath(~x"./itunes:summary/text()"s)
                     }
                   end)

    File.close xml
  end
end