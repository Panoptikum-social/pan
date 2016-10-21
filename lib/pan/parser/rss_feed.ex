defmodule Pan.Parser.RssFeed do
  use Pan.Web, :controller
  alias Pan.Parser.Helpers

  def demo() do
    download_and_parse("http://freakshow.fm/feed/m4a")
  end

  def download_and_parse(url) do
#    %HTTPoison.Response{body: feed_as_xml} = HTTPoison.get!(url, [], [follow_redirect: true,
#                                                                      connect_timeout: 20000,
#                                                                      recv_timeout: 20000,
#                                                                      timeout: 20000])

    feed_as_xml = File.read! "materials/source.xml"

    # {:ok, xml} = Pan.Parser.Helpers.fix_missing_xml_tag(xml)

    Quinn.parse(feed_as_xml)
    |> parse
  end


  def parse(feed) do
    podcast = Pan.Podcast.changeset(%Pan.Podcast{})
    parse(podcast, feed)
  end


  def parse(podcast, _, []), do: podcast

  def parse(podcast, context \\ "tag", [head | tail]) do
    podcast = analyze(podcast, context, [head[:name], head[:attr], head[:value]])
    parse(podcast, context, tail)
    podcast
  end


  def analyze(podcast, "tag", [:rss,     _, value]), do: parse(podcast, "tag", value)
  def analyze(podcast, "tag", [:channel, _, value]), do: parse(podcast, "tag", value)

  def analyze(podcast, "tag", [:"feedpress:locale", _, value]), do: podcast
  def analyze(podcast, "tag", [:image, _, value]), do: parse(podcast, "image", value)

  def analyze(podcast, "tag", [:title,       _, [value]]), do: Ecto.Changeset.change(podcast, title: value)
  def analyze(podcast, "tag", [:link,        _, [value]]), do: Ecto.Changeset.change(podcast, website: value)
  def analyze(podcast, "tag", [:description, _, [value]]), do: Ecto.Changeset.change(podcast, description: value)


  def analyze(podcast, "tag", [:lastBuildDate, _, [value]]) do
    lastbuilddate = Pan.Parser.Helpers.to_ecto_datetime(value)
    Ecto.Changeset.change(podcast, lastBuildDate: lastbuilddate)
  end

  def analyze(podcast, "image", [:title, _, [value]]), do: Ecto.Changeset.change(podcast, image_title: value)
  def analyze(podcast, "image", [:url, _, [value]]),   do: Ecto.Changeset.change(podcast, image_url: value)
  def analyze(podcast, "image", [:link, _, [value]]),  do: podcast


  def analyze(podcast, "tag", [:"itunes:image"], attr, _) do
    unless podcast.changes.image_url do
      podcast = Ecto.Changeset.change(podcast, image_url: attr[:href])
      podcast = Ecto.Changeset.change(podcast, image_title: attr[:href])
    end
    podcast
  end

  def analyze(_, context, [name, _, _]) do
    IO.puts "=== name:"
    IO.puts name
    IO.puts "=== context:"
    IO.puts context
    IO.puts "======"
  end


  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end