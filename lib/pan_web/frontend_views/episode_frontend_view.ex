defmodule PanWeb.EpisodeFrontendView do
  use PanWeb, :view
  alias PanWeb.Like
  alias PanWeb.Episode

  def author_button(conn, episode) do
    persona = Episode.author(episode)

    if persona do
      link([icon("user-heroicons-outline"), " ", persona.name],
        to: persona_frontend_path(conn, :show, persona.id),
        class: "btn btn-xs truncate btn-lavender"
      )
    else
      [icon("user-heroicons-outline"), " Unknown"]
    end
  end

  def list_group_item_cycle(counter) do
    Enum.at(
      [
        "list-group-item-info",
        "list-group-item-danger",
        "list-group-item-warning",
        "list-group-item-primary",
        "list-group-item-success"
      ],
      rem(counter, 5)
    )
  end

  def like_or_unlike(user_id, episode_id) do
    case Like.find_episode_like(user_id, episode_id) do
      nil ->
        content_tag :button,
          class: "btn btn-warning",
          data: [type: "episode", event: "like", action: "like", id: episode_id] do
          [Episode.likes(episode_id), " ", icon("heart-heroicons-outline"), " Like"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "episode", event: "like", action: "unlike", id: episode_id] do
          [Episode.likes(episode_id), " ", icon("heart-heroicons-outline"), " Unlike"]
        end
    end
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
    link("Complain", to: "https://panoptikum.io/complaints")
  end
end
