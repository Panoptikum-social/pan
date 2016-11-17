defmodule Pan.PodcastFrontendView do
  use Pan.Web, :view

  def panel_cycle(counter) do
    Enum.at(["panel-default", "panel-info", "panel-danger",
             "panel-warning", "panel-primary", "panel-success"], rem(counter, 6))
  end


  def like_or_unlike(conn, user, podcast) do
    case Pan.Repo.get_by(Pan.Like, enjoyer_id: user.id,
                                   podcast_id: podcast.id) do
      nil ->
        link fa_icon("heart-o"),   to: podcast_frontend_path(conn, :like,   podcast), data: [type: "podcast", action: "like"]
      _   ->
        link fa_icon("heart"), to: podcast_frontend_path(conn, :like, podcast), data: [type: "podcast", action: "unlike"]
    end
  end
end