defmodule Pan.EpisodeFrontendView do
  use Pan.Web, :view
  alias Pan.Repo
  alias Pan.Like

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
      extensions: %{ChapterMarks: %{},
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


  def like_or_unlike(user_id, episode_id) do
    case Like.find_by(user_id, episode_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "episode",
                                    event: "like",
                                    action: "like",
                                    id: episode_id] do
          [fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "episode",
                                    event: "like",
                                    action: "unlike" ,
                                    id: episode_id] do
          [fa_icon("heart"), " Unlike"]
        end
    end
  end

  def render("like_button.html", %{user_id: user_id, episode_id: episode_id}) do
    like_or_unlike(user_id, episode_id)
  end


  def like_or_unlike_chapter(user_id, chapter_id) do
    case Repo.get_by(Pan.Like, enjoyer_id: user_id,
                               chapter_id: chapter_id) do
      nil ->
        content_tag :button, class: "btn btn-warning btn-xs",
                             data: [type: "chapter",
                                    event: "like-chapter",
                                    action: "like",
                                    id: chapter_id] do
          [fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success btn-xs",
                             data: [type: "chapter",
                                    event: "like-chapter",
                                    action: "unlike" ,
                                    id: chapter_id] do
          [fa_icon("heart"), " Unlike"]
        end
    end
  end

  def render("like_chapter_button.html", %{user_id: user_id, chapter_id: chapter_id}) do
    like_or_unlike_chapter(user_id, chapter_id)
  end
end