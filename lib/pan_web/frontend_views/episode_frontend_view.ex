defmodule PanWeb.EpisodeFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML
  alias Pan.Repo
  alias PanWeb.Like
  alias PanWeb.Episode
  alias PanWeb.Chapter
  alias PanWeb.Gig
  alias PanWeb.User
  alias PanWeb.Persona


  def author_button(conn, episode) do
    persona = Episode.author(episode)
    if persona do
      link [fa_icon("user-o"), " ", persona.name],
           to: persona_frontend_path(conn, :show, persona.id),
           class: "btn btn-xs truncate btn-lavender"
    else
      [fa_icon("user-o"), " Unknown"]
    end
  end


  def podlove_episodestruct(conn, episode) do
    %{show: %{title: episode.podcast.title,
              subtitle: episode.podcast.summary,
              summary: episode.podcast.description,
              poster: episode.podcast.image_url,
              link: episode.podcast.website
             },
      title: episode.title,
      subtitle: episode.description,
      summary: episode.summary,
      poster: episode.podcast.image_url,
      publicationDate: episode.publishing_date,
      duration: episode.duration,
      link: episode.link,
#      theme: %{main: '#2B8AC6', highlight: '#EC79F2'},
      tabs: %{chapters: true},
      contributors: contributorlist(episode.gigs),
      chapters: chapterlist(episode.chapters),
      audio: audiolist(episode.enclosures),
      reference: %{base: PanWeb.Endpoint.url <> "podlove-webplayer/",
                   share: episode_frontend_path(conn, :show, episode.id)}
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


  defp contributorlist(gigs) do
    Enum.map(gigs, fn(gig) ->
      %{name: gig.persona.name,
        role: %{id: 1,
                slug: gig.role,
                title: gig.role
               }
       }
    end)
  end


  defp enclosuremap(enclosures) do
    Enum.map(enclosures, fn(enclosure) ->
      %{filetype(enclosure) => enclosure.url}
    end)
    |> List.first
  end


# for podlove
  def audiolist(enclosures) do
    Enum.map(enclosures, fn(enclosure) ->
      %{url: enclosure.url,
        mimeType: enclosure.type,
        size: enclosure.length,
        title: String.split(enclosure.url, "/") |> List.last}
    end)
  end


# for podigee
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
    case Repo.get_by(PanWeb.Like, enjoyer_id: user_id,
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


  def proclaim_or_not_buttons(user_id, episode_id) do
    user = Repo.get!(User, user_id)
           |> Repo.preload(:personas)

    for persona <- user.personas do
      proclaim_or_not(episode_id, persona)
      # [proclaim_or_not(episode_id, persona), tag(:br)]
    end
  end


  def proclaim_or_not(episode_id, persona) do
    case Gig.find_self_proclaimed(persona.id, episode_id) do
      nil ->
        content_tag :span do
          [" ",
           content_tag :button, class: "btn btn-inverse-lavender btn-xs",
                                title: "Claim contribution for #{persona.pid}",
                                data: [type: "persona",
                                       event: "proclaim",
                                       personaid: persona.id,
                                       id: episode_id] do
               [fa_icon("user-plus"), " ", persona.name]
           end]
        end
      _   ->
        content_tag :span do
          [" ",
            content_tag :button, class: "btn btn-lavender btn-xs",
                                 title: "Withdraw contribution for #{persona.pid}",
                                 data: [type: "persona",
                                        event: "proclaim",
                                        personaid: persona.id,
                                        id: episode_id] do
              [fa_icon("user-times"), " ", persona.name]
            end]
        end
    end
  end


  def render("like_button.html", %{user_id: user_id, episode_id: episode_id}) do
    like_or_unlike(user_id, episode_id)
  end

  def render("like_chapter_button.html", %{user_id: user_id, chapter_id: chapter_id}) do
    like_or_unlike_chapter(user_id, chapter_id)
  end

  def render("proclaim_button.html", %{episode_id: episode_id, persona_id: persona_id}) do
    persona = Repo.get(Persona, persona_id)
    proclaim_or_not(episode_id, persona)
  end


  def seconds(time), do: String.split(time, ":") |> splitseconds()
  def to_i(string), do: String.to_integer(string)
  def to_s(integer), do: Integer.to_string(integer)

  def splitseconds([hours, minutes, seconds, _milliseconds]) do
    (to_i(hours) * 3600 + to_i(minutes) * 60 + to_i(seconds))
    |> to_s()
  end

  def splitseconds([hours, minutes, seconds_string]) do
    {seconds, _} = Integer.parse(seconds_string)
    (to_i(hours) * 3600 + to_i(minutes) * 60 + seconds)
    |> to_s()
  end

  def splitseconds([hours, minutes]) do
    (to_i(hours) * 3600 + to_i(minutes) * 60)
    |> to_s()
  end


  def complain_link() do
    link "Complain", to: "https://panoptikum.io/complaints"
  end


  def major_mimetype(episode) do
    if mimetype(episode) do
      mimetype(episode)
      |> String.split("/")
      |> List.first()
    end
  end

  def mimetype(episode) do
    if episode.enclosures != [] do
      episode.enclosures
      |> List.first()
      |> Map.get(:type)
    end
  end
end