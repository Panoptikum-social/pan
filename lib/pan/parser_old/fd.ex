defmodule Pan.Parser.FD do
  alias Pan.Feed
  import SweetXml

  def parse(xml, url) do
    self_link = parse_self_link(xml, url)

    next_page_url  = xml |> xpath(~x"//channel/atom:link[@rel='next']//@href"s)
    prev_page_url  = xml |> xpath(~x"//channel/atom:link[@rel='prev']//@href"s)
    first_page_url = xml |> xpath(~x"//channel/atom:link[@rel='first']//@href"s)
    last_page_url  = xml |> xpath(~x"//channel/atom:link[@rel='last']//@href"s)
    hub_link_url   = xml |> xpath(~x"//channel/atom:link[@rel='hub']//@href"s)
    feed_generator = xml |> xpath(~x"//channel/generator/text()"s)

    feed = %Feed{self_link_title: self_link.title,
                 self_link_url:   self_link.url,
                 next_page_url:   next_page_url,
                 prev_page_url:   prev_page_url,
                 first_page_url:  first_page_url,
                 last_page_url:   last_page_url,
                 hub_link_url:    hub_link_url,
                 feed_generator:  feed_generator}
    {:ok, feed}
  end


  defp parse_self_link(xml, url) do
    if xml |> xpath(~x"//channel/atom:link[@rel='self']") do
      xml |> xpath(~x"//channel/atom:link[@rel='self']",
                   title: ~x"./@title"s,
                   url: ~x"./@href"s)
    else
      %{title: "Feed", url: url }
    end
  end
end