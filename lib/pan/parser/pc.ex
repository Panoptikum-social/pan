defmodule Pan.Parser.PC do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Parser.Helpers
  import SweetXml

  def parse(xml) do
    title = xml |> xpath(~x"//channel/title/text()"s)
    website = xml |> xpath(~x"//channel/link/text()"s)
    description = xml |> xpath(~x"//channel/description/text()"s)
    summary = xml |> xpath(~x"//channel/itunes:summary/text()"s)
    author = xml |> xpath(~x"//channel/itunes:author/text()"s)
    explicit = xml
               |> xpath(~x"//channel/itunes:iexplicit/text()"s)
               |> Helpers.boolify

    image =
      cond do
        xml |> xpath(~x"//channel/image") != nil ->
          xml |> xpath(~x"//channel/image", title: ~x"./title/text()"s,
                                            url: ~x"./url/text()"s)
        xml |> xpath(~x"//channel/itunes:image") != nil ->
          xml |> xpath(~x"//channel/itunes:image", title: ~x"./@href"s ,
                                                   url: ~x"./@href"s)
      end



    payment_link = parse_payment_link(xml)

    language_id =
      if xml |> xpath(~x"//channel/language/text()"s) != "" do
        {:ok, language} = xml
                          |> xpath(~x"//channel/language/text()"s)
                          |> Helpers.find_language
        language.id
      else
        nil
      end

    last_build_date = xml
                      |> xpath(~x"//channel/lastBuildDate/text()"s)
                      |> Helpers.to_ecto_datetime

    podcast = %Podcast{title: title,
                       website: website,
                       description: description,
                       language_id: language_id,
                       summary: summary,
                       image_title: image.title,
                       image_url: image.url,
                       last_build_date: last_build_date,
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