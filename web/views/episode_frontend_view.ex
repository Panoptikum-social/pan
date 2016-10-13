defmodule Pan.EpisodeFrontendView do
  use Pan.Web, :view

  def episodestruct(episode) do
    mystruct = %{poster: episode.podcast.image_url,
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

    raw(Poison.encode!(mystruct))
  end

  def chapterlist(chapters) do
    Enum.map(chapters, fn(chapter) -> %{start: chapter.start,
                                        title: chapter.title} end)
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