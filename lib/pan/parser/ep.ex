defmodule Pan.Parser.EP do
  alias Pan.Parser.Helpers
  import SweetXml

  def parse(xml) do
   episodes =
     xml
     |> xpath(~x"//channel/item"l)
     |> Enum.map( fn (episode) ->
       %{title: episode
                |> xpath(~x"./title/text()"s),
         link:  episode
                |> xpath(~x"./link/text()"s),
         publishing_date: episode
                          |> xpath(~x"./pubDate/text()"s)
                          |> Helpers.to_ecto_datetime,
         guid: episode
               |> xpath(~x"./guid/text()"s),
         description: episode
                      |> xpath(~x"./description/text()"s),
         shownotes: episode
                    |> xpath(~x"./content:encoded/text()"s),
         payment_link: parse_payment_link(episode),
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
         enclosures: episode
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

    {:ok, episodes}
  end


  def parse_payment_link(episode) do
    if episode |> xpath(~x"./atom:link[@rel='payment']") do
      episode |> xpath(~x"./atom:link[@rel='payment']",
                       title: ~x"./@title"s,
                       url: ~x"./@href"s)
    else
      %{title: "", url: ""}
    end
  end
end