defmodule PanWeb.Live.Episode.PodlovePlayer do
  use Surface.LiveComponent
  alias PanWeb.Endpoint
  alias Phoenix.HTML
  import PanWeb.Router.Helpers

  prop(episode, :map, required: true)
  prop(class, :css_class, default: "")

  def handle_event("read-config", _, %{assigns: assigns} = socket) do
    config = %{
      episode: assigns.episode |> episode_config(),
      config: assigns.episode.podcast |> playerconfig()
    }

    {:reply, config, socket}
  end

  defp episode_config(episode) do
    poster = Endpoint.url() <> "/images/missing-podcast.png"

    %{
      version: 5,
      show: %{
        title: episode.podcast.title,
        subtitle: episode.podcast.summary,
        summary: episode.podcast.description,
        poster: poster,
        link: episode.podcast.website
      },
      title: episode.title,
      subtitle: HtmlSanitizeEx.strip_tags(episode.description),
      summary: HtmlSanitizeEx.strip_tags(episode.summary),
      poster: poster,
      publicationDate: episode.publishing_date,
      duration: episode.duration,
      link: episode_frontend_url(Endpoint, :show, episode.id),
      theme: %{main: "#eee"},
      tabs: %{chapters: true},
      contributors: contributorlist(episode.gigs),
      chapters: chapterlist(episode.chapters),
      audio: audiolist(episode.enclosures)
    }
  end

  defp contributorlist(gigs) do
    Enum.map(gigs, fn gig ->
      %{name: gig.persona.name, role: %{id: 1, slug: gig.role, title: gig.role}}
    end)
  end

  defp chapterlist(chapters) do
    Enum.map(chapters, fn chapter ->
      %{
        start: HTML.javascript_escape(chapter.start || ""),
        title: HTML.javascript_escape(chapter.title || "")
      }
    end)
  end

  defp audiolist(enclosures) do
    Enum.map(enclosures, fn enclosure ->
      %{
        url: enclosure.url,
        mimeType: enclosure.type,
        size: enclosure.length,
        title: String.split(enclosure.url, "/") |> List.last()
      }
    end)
  end

  defp playerconfig(podcast) do
    feed_url = podcast.feeds |> List.first() |> Map.get(:self_link_url)

    %{
      version: 5,
      activeTab: "chapters",
      base: PanWeb.Endpoint.url() <> "/web-player/",
      share: %{
        channels: [
          "facebook",
          "twitter",
          "whats-app",
          "linkedin",
          "pinterest",
          "xing",
          "mail",
          "link"
        ],
        sharePlaytime: true
      },
      "subscribe-button": %{
        feed: feed_url,
        clients: [
          %{id: "antenna-pod"},
          %{id: "beyond-pod"},
          %{id: "castro"},
          %{id: "clementine"},
          %{id: "downcast"},
          %{id: "google-podcasts", service: feed_url},
          %{id: "gpodder"},
          %{id: "itunes"},
          %{id: "i-catcher"},
          %{id: "instacast"},
          %{id: "overcast"},
          %{id: "player-fm"},
          %{id: "pocket-casts"},
          %{id: "pocket-casts", service: feed_url},
          %{id: "pod-grasp"},
          %{id: "podcast-addict"},
          %{id: "podcast-republic"},
          %{id: "podcat"},
          %{id: "podscout"},
          %{id: "rss-radio"},
          %{id: "rss"}
        ]
      }
    }
  end

  def render(assigns) do
    ~F"""
    <div :hook="PodlovePlayer"
         id="podlove-player"
         class={"podlove-player shrink-0", @class} />
    """
  end
end
