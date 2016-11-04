defmodule Pan.EpisodeFrontendView do
  use Pan.Web, :view

  def podlove_episodestruct(episode) do
    %{poster: episode.podcast.image_url,
      title: episode.title,
      subtitle: episode.description,
      alwaysShowHours: true,
      startVolume: 0.8,
      width: "auto",
      summaryVisible: false,
      timecontrolsVisible: false,
      chaptersVisible: true,
      sharebuttonsVisible: false,
      summary: episode.summary,
      duration: episode.duration,
      permalink: episode.deep_link,
      activeTab: "chapters",
      show: %{title: episode.podcast.title,
              subtitle: episode.podcast.summary,
              summary: episode.podcast.description,
              poster: episode.podcast.image_url,
              url: episode.link},
      chapters: chapterlist(episode.chapters),
      downloads: downloadlist(episode.enclosures)
    }
    |> Poison.encode!
    |> raw
  end


  def podigee_episodestruct(episode) do
    %{options: %{theme: "default",
                 startPanel: "ChapterMarks"},
      extensions: %{Chaptermarks: %{},
                    EpisodeInfo: %{},
                    Playlist: %{}},
      title: episode.podcast.title,
      episode: %{media: enclosuremap(episode.enclosures),
                 coverUrl: episode.podcast.image_url,
                 title: episode.title,
                 subtitle: episode.subtitle,
                 url: episode.deep_link,
                 description: episode.description,
                 chaptermarks: chapterlist(episode.chapters)
               }
    }
    |> Poison.encode!
    |> raw
  end


  defp filetype (enclosure) do
    enclosure.url |> String.split(".") |> List.last |> String.to_atom
  end


  defp chapterlist(chapters) do
    Enum.map(chapters, fn(chapter) -> %{start: chapter.start,
                                        title: chapter.title} end)
  end


  defp enclosuremap(enclosures) do
    Enum.map(enclosures, fn(enclosure) -> %{filetype(enclosure) => enclosure.url} end)
    |> List.first
  end


  def downloadlist(enclosures) do
    Enum.map(enclosures, fn(enclosure) -> %{assetTitle: String.split(enclosure.url, "/") |> List.last,
                                            size: enclosure.length,
                                            downloadUrl: enclosure.url} end)
  end


  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary", "list-group-item-success"], rem(counter, 5))
  end
end