defmodule Pan.Parser.PC do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Parser.Helpers
  import SweetXml

  def parse(xml) do
    summary = xml |> xpath(~x"//channel/itunes:summary/text()"s)
    author = xml |> xpath(~x"//channel/itunes:author/text()"s)
    explicit = xml
               |> xpath(~x"//channel/itunes:iexplicit/text()"s)
               |> Helpers.boolify


    payment_link = parse_payment_link(xml)

    podcast = %Podcast{summary: summary,
                       payment_link_title: payment_link.title,
                       payment_link_url: String.slice(payment_link.url, 0, 255),
                       author: author,
                       explicit: explicit
                       }
    {:ok, podcast}
  end


  def parse_payment_link(xml) do
    if xml |> xpath(~x"//channel/atom:link[@rel='payment']") do
      xml |> xpath(~x"//channel/atom:link[@rel='payment']",
                   title: ~x"./@title"s,
                   url: ~x"./@href"s)
    else
      %{title: "", url: ""}
    end
  end
end