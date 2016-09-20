defmodule Pan.Parser do
  use Pan.Web, :controller
  alias Pan.Feed
  alias Pan.Podcast
  alias Pan.User
  alias Pan.Language
  import SweetXml

  @path_to_file "materials/freakshow.xml"


  def update() do
    path_to_file = @path_to_file

    {:ok, feed} = parse_feed(path_to_file)

    case Repo.get_by(Feed, self_link_url: feed.self_link_url) do
      nil ->
        {:ok, owner} = find_or_create_owner(path_to_file)

        {:ok, podcast} = parse_podcast(path_to_file)
        {:ok, podcast} = Repo.insert(%{podcast | owner_id: owner.id})

        {:ok, feed} = parse_feed(path_to_file)
        {:ok, feed} = Repo.insert(%{feed | podcast_id: podcast.id})

      feed ->
        IO.puts "feed found, do nothing"
    end
  end


  def find_or_create_owner(path_to_file) do
    {:ok, feed_owner} = parse_owner(path_to_file)

    {:ok, owner} =
      case Repo.get_by(User, email: feed_owner.email) do
        nil ->
           Repo.insert(feed_owner)
        user ->
          {:ok, user}
      end
  end


  def read_feed(path_to_file) do
    File.read(path_to_file)
  end


  def parse_podcast(path_to_file) do
    {:ok, xml} = read_feed(path_to_file)

    title = xml |> xpath(~x"//channel/title/text()"s)
    website = xml |> xpath(~x"//channel/link/text()"s)
    description = xml |> xpath(~x"//channel/description/text()"s)
    summary = xml |> xpath(~x"//channel/itunes:summary/text()"s)
    author = xml |> xpath(~x"//channel/itunes:author/text()"s)
    explicit = xml 
               |> xpath(~x"//channel/itunes:iexplicit/text()"s) 
               |> boolify

    image = xml |> xpath(~x"//channel/image", title: ~x"./title/text()"s,
                                              url: ~x"./url/text()"s)
    payment_link = xml |> xpath(~x"//channel/atom:link[@rel='payment']",
                                title: ~x"./@title"s,
                                url: ~x"./@href"s)

    {:ok, language} = xml
                      |> xpath(~x"//channel/language/text()"s)
                      |> find_language
    last_build_date = xml
                      |> xpath(~x"//channel/lastBuildDate/text()"s)
                      |> to_ecto_datetime

    podcast = %Podcast{title: title,
                       website: website,
                       description: description,
                       language_id: language.id,
                       summary: summary,
                       image_title: image.title,
                       image_url: image.url,
                       last_build_date: last_build_date,
                       payment_link_title: payment_link.title,
                       payment_link_url: payment_link.url,
                       author: author,
                       explicit: false
                       }
    File.close xml

    {:ok, podcast}
  end


  def to_ecto_datetime(feed_date) do
    {:ok, datetime} = Timex.parse(feed_date, "{RFC1123}")
    # why can't I pipe here?
    erltime = Timex.to_erl(datetime)
    Ecto.DateTime.from_erl(erltime)
  end


  def boolify(explicit) do
    case explicit do
      "yes" ->
        true
      _ ->
        false
    end    
  end


  def find_language(shortcode) do
    {:ok, Repo.get_by(Language, shortcode: shortcode)}
  end


  def parse_owner(path_to_file) do
    {:ok, xml} = read_feed(path_to_file)

    owner = xml
        |> xpath(~x"//channel/itunes:owner",
                 name: ~x"./itunes:name/text()"s,
                 email: ~x"./itunes:email/text()"s)

    File.close xml
    {:ok, %User{name: owner.name, 
                email: owner.email, 
                username: owner.email, 
                podcaster: true}}
  end


  def parse_feed(path_to_file) do
    {:ok, xml} = read_feed(path_to_file)

    self_link = xml
                |> xpath(~x"//channel/atom:link[@rel='self']",
                         title: ~x"./@title"s,
                         url: ~x"./@href"s)
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
    File.close xml
    {:ok, feed}
  end


  def parse_all_the_rest(path_to_file) do
    {:ok, xml} = read_feed(path_to_file)

    alternate_feeds = xml
                      |> xpath(~x"//channel/atom:link[@rel='alternate']"l,
                      title: ~x"./@title"s,
                      url: ~x"./@href"s)

    contributers = xml
                   |> xpath(~x"//channel/atom:contributor"l,
                            name: ~x"./atom:name/text()"s,
                            uri: ~x"./atom:uri/text()"s)

    categories = xml
                 |> xpath(~x"//channel/itunes:category"l,
                          title: ~x"./@text"s,
                          subtitle: ~x"./itunes:category/@text"s)

    episodes =  xml
                |> xpath(~x"//channel/item"l)
                |> Enum.map( fn (episode) ->
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
                                              url: ~x"./@href"s),
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
                   end )
    File.close xml
  end
end
