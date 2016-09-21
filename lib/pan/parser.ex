defmodule Pan.Parser do
  use Pan.Web, :controller
  alias Pan.Feed
  alias Pan.Podcast
  alias Pan.User
  alias Pan.Language
  alias Pan.Episode
  alias Pan.AlternateFeed
  alias Pan.Contributor
  alias Pan.Category
  alias Pan.Chapter
  alias Pan.Enclosure
  alias Pan.Repo
  import SweetXml

  @path_to_file "materials/freakshow.xml"


  def update() do
    {:ok, xml} = File.read(@path_to_file)
    {:ok, feed} = parse_feed(xml)

    case Repo.get_by(Feed, self_link_url: feed.self_link_url) do
      nil ->
        create_podcast(xml)
      feed ->
        {ok, episodes} = parse_episodes(xml)
        find_or_create_episodes(episodes, feed.podcast_id)
    end

    File.close xml
  end


  def create_podcast(xml) do
    {:ok, owner} = find_or_create_owner(xml)

    {:ok, podcast} = parse_podcast(xml)
    {:ok, podcast} = Repo.insert(%{podcast | owner_id: owner.id})

    {:ok, feed} = parse_feed(xml)
    {:ok, feed} = Repo.insert(%{feed | podcast_id: podcast.id})

    create_alternate_feeds(xml, feed)
    create_contributors(xml, podcast)
    create_categories(xml, podcast)
  end


  def create_alternate_feeds(xml, feed) do
    {:ok, alternate_feeds} = parse_alternate_feeds(xml)

    for alternate_feed <- alternate_feeds do
      {:ok, _alternate_feed} = create_alternate_feed(alternate_feed, feed.id)
    end
  end


  def create_alternate_feed(alternate_feed, feed_id) do
    Repo.insert(
      %AlternateFeed{title:    alternate_feed.title,
                      url:     alternate_feed.url,
                      feed_id: feed_id})
  end


  def create_contributors(xml, podcast) do
    {:ok, contributors} = parse_contributors(xml)

    for contributor <- contributors do
      if Repo.get_by(Contributor, uri: contributor.uri) == nil do
        {:ok, contributor} = create_contributor(contributor)

        associate(contributor, podcast)
      end
    end
  end


  def create_categories(xml, podcast) do
    {:ok, categories} = parse_categories(xml)

    for category <- categories do
      category =
        if category.subtitle == nil  do
          Category.find_or_create(category)
        else
          parent = Category.find_or_create(%Category{title: category.title})
          Category.find_or_create(%Category{title: category.subtitle,
                                            parent_id: parent.id})
        end

      associate(category, podcast)
    end
  end


  def associate(instance, podcast) do
    instance
    |> Repo.preload(:podcasts)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:podcasts, [podcast])
    |> Repo.update!
  end


  def find_or_create_episodes(episodes, podcast_id) do
    for xml_episode <- episodes do
      if (Repo.get_by(Episode, guid: xml_episode.guid) == nil and
          Repo.get_by(Episode, link: xml_episode.link) == nil) do

        {:ok, episode} = create_episode(xml_episode, podcast_id)

        for chapter <- xml_episode.chapters do
          {:ok, _chapter} = create_chapter(chapter, episode.id)
        end

      #  for enclosure <- xml_episode.enclosures do
      #    {:ok, _enclosure} = create_enclosure(enclosure, episode.id)
      #   end

      #   for contributor <- xml_episode.contributors do
      #     {:ok, _contributor} = find_or_create_episode_contributor(contributor, episode)
      #   end
      end
    end
  end


  def find_or_create_episode_contributor(contributor, episode) do
    if (Repo.get_by(Contributor, uri: episode.uri) == nil) do
      {:ok, contributor} = create_contributor(contributor)

      contributor
      |> Repo.preload(:episodes)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:episodes, [episode])
      |> Repo.update!
    end
  end


  def create_contributor(contributor) do
    Repo.insert(
      %Contributor{name: contributor.name,
                   uri:  contributor.uri})
  end


  def create_enclosure(enclosure, episode_id) do
    Repo.insert(
      %Enclosure{url:        enclosure.url,
               length:     enclosure.length,
               type:       enclosure.type,
               guid:       enclosure.guid,
               episode_id: episode_id})
  end


  def create_chapter(chapter, episode_id) do
    Repo.insert(
      %Chapter{start:      chapter.start,
               title:      chapter.title,
               episode_id: episode_id})
  end


  def create_episode(episode, podcast_id) do
    Repo.insert(
      %Episode{title:              episode.title,
               link:               episode.link,
               publishing_date:    episode.publishing_date,
               guid:               episode.guid,
               description:        episode.description,
               shownotes:          episode.shownotes,
               payment_link_title: episode.payment_link.title,
               payment_link_url:   String.slice(episode.payment_link.url, 0, 255),
               deep_link:          episode.deep_link,
               duration:           episode.duration,
               author:             episode.author,
               subtitle:           episode.subtitle,
               summary:            episode.summary,
               podcast_id:         podcast_id})
  end


  def find_or_create_owner(xml) do
    {:ok, feed_owner} = parse_owner(xml)

    {:ok, owner} =
      case Repo.get_by(User, email: feed_owner.email) do
        nil ->
           Repo.insert(feed_owner)
        user ->
          {:ok, user}
      end

    {:ok, owner}
  end


  def parse_podcast(xml) do
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
                       explicit: explicit
                       }
    {:ok, podcast}
  end


  def to_ecto_datetime(feed_date) do
    {:ok, datetime} = Timex.parse(feed_date, "{RFC1123}")

    erltime = Timex.to_erl(datetime)
    # why can't I pipe here?
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


  def parse_owner(xml) do
    owner = xml
            |> xpath(~x"//channel/itunes:owner",
                     name: ~x"./itunes:name/text()"s,
                     email: ~x"./itunes:email/text()"s)

    {:ok, %User{name: owner.name,
                email: owner.email,
                username: owner.email,
                podcaster: true}}
  end


  def parse_feed(xml) do
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
    {:ok, feed}
  end

  def parse_episodes(xml) do
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
                          |> to_ecto_datetime,
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
     end)
    {:ok, episodes}
  end


  def parse_alternate_feeds(xml) do
    alternate_feeds = xml
                      |> xpath(~x"//channel/atom:link[@rel='alternate']"l,
                      title: ~x"./@title"s,
                      url: ~x"./@href"s)
    {:ok, alternate_feeds}
  end


  def parse_contributors(xml) do
    contributors = xml
                   |> xpath(~x"//channel/atom:contributor"l,
                            name: ~x"./atom:name/text()"s,
                            uri: ~x"./atom:uri/text()"s)
    {:ok, contributors}
  end


  def parse_categories(xml) do
    categories = xml
                 |> xpath(~x"//channel/itunes:category"l,
                          title: ~x"./@text"s,
                          subtitle: ~x"./itunes:category/@text"s)
    {:ok, categories}
  end
end
