defmodule PanWeb.Live.Episode.PodloveWebplayer do
  use Surface.Component
  alias PanWeb.Endpoint
  import  Phoenix.HTML, only: [javascript_escape: 1, raw: 1]
  import PanWeb.Router.Helpers

  prop(episode, :map, required: true)
  data(episodestruct, :map)

  defp podlove_episodestruct(episode) do
    poster = Endpoint.url() <> "/images/missing-podcast.png"

    %{
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
      audio: audiolist(episode.enclosures),
      reference: %{base: PanWeb.Endpoint.url() <> "/podlove-webplayer/"}
    }
    |> Jason.encode!()
    |> raw
  end

  defp contributorlist(gigs) do
    Enum.map(gigs, fn gig ->
      %{name: gig.persona.name, role: %{id: 1, slug: gig.role, title: gig.role}}
    end)
  end

  defp chapterlist(chapters) do
    Enum.map(chapters, fn chapter ->
      %{start: escape_javascript(chapter.start), title: escape_javascript(chapter.title)}
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

  defp escape_javascript(nil), do: ""
  defp escape_javascript(string), do: javascript_escape(string)

  def render(assigns) do
    assign(assigns, episodestruct: assigns.episode |> podlove_episodestruct)

    ~F"""
    <div id="podlove-webplayer"></div>
    <script src="/podlove-webplayer/embed.js"></script>
    <script>
      podlovePlayer('#podlove-webplayer', {@episodestruct})
    </script>
    """
  end
end
