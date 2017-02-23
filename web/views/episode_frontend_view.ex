defmodule Pan.EpisodeFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML
  alias Pan.Repo
  alias Pan.Like
  alias Pan.Episode
  alias Pan.Chapter


  def author_button(conn, episode) do
    persona = Episode.author(episode)
    if persona do
      link [fa_icon("user-o"), " ", persona.name],
           to: persona_frontend_path(conn, :show, persona.id),
           class: "btn btn-xs truncate btn-bittersweet"
    else
      [fa_icon("user-o"), " Unknown"]
    end
  end


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
                 startPanel: "ChapterMarks",
                 sslProxy: "https://cdn.podigee.com/ssl-proxy/"},
      extensions: %{ChapterMarks: %{},
                    EpisodeInfo: %{},
                    Playlist: %{},
                    Share: %{},
                    Transcript: %{},
                    Waveform: %{}},
      title: ej(episode.podcast.title),
      episode: %{media: enclosuremap(episode.enclosures),
                 coverUrl: episode.podcast.image_url,
                 title: ej(episode.title),
                 subtitle: ej(episode.subtitle),
                 url: episode.deep_link || episode.link,
                 description: episode.description
                              |> HtmlSanitizeEx.strip_tags
                              |> truncate(1000)
                              |> ej(),
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
    Enum.map(chapters, fn(chapter) ->
      %{start: ej(chapter.start), title: ej(chapter.title)}
    end)
  end


  defp enclosuremap(enclosures) do
    Enum.map(enclosures, fn(enclosure) ->
      %{filetype(enclosure) => enclosure.url}
    end)
    |> List.first
  end


  def downloadlist(enclosures) do
    Enum.map(enclosures, fn(enclosure) ->
      %{assetTitle: String.split(enclosure.url, "/") |> List.last,
        size: enclosure.length,
        downloadUrl: enclosure.url}
    end)
  end


  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary",
             "list-group-item-success"], rem(counter, 5))
  end


  def like_or_unlike(user_id, episode_id) do
    case Like.find_episode_like(user_id, episode_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "episode",
                                    event: "like",
                                    action: "like",
                                    id: episode_id] do
          [Episode.likes(episode_id), " ", fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "episode",
                                    event: "like",
                                    action: "unlike" ,
                                    id: episode_id] do
          [Episode.likes(episode_id), " ", fa_icon("heart"), " Unlike"]
        end
    end
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
          [Chapter.likes(chapter_id), " ", fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success btn-xs",
                             data: [type: "chapter",
                                    event: "like-chapter",
                                    action: "unlike" ,
                                    id: chapter_id] do
          [Chapter.likes(chapter_id), " ", fa_icon("heart"), " Unlike"]
        end
    end
  end


  def render("like_button.html", %{user_id: user_id, episode_id: episode_id}) do
    like_or_unlike(user_id, episode_id)
  end

  def render("like_chapter_button.html", %{user_id: user_id, chapter_id: chapter_id}) do
    like_or_unlike_chapter(user_id, chapter_id)
  end


  def seconds(time) do
    [hours, minutes, seconds_string] = String.split(time, ":")
    {seconds, _} = Integer.parse(seconds_string)
    Integer.to_string(String.to_integer(hours) * 3600 + String.to_integer(minutes) * 60 + seconds)
  end


  def complain_link() do
    link "Complain", to: "https://panoptikum.io/complaints", style: "color: #fff;"
  end
end