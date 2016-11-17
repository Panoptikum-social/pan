defmodule Pan.PodcastFrontendView do
  use Pan.Web, :view

  def panel_cycle(counter) do
    Enum.at(["panel-default", "panel-info", "panel-danger",
             "panel-warning", "panel-primary", "panel-success"], rem(counter, 6))
  end


  def like_or_unlike(user_id, podcast_id) do
    case Pan.Repo.get_by(Pan.Like, enjoyer_id: user_id,
                                   podcast_id: podcast_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "podcast",
                                    action: "like",
                                    id: podcast_id] do
          [fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "podcast",
                             action: "unlike" ,
                             id: podcast_id] do
          [fa_icon("heart"), " Unlike"]
        end
    end
  end

  def render("button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    like_or_unlike(user_id, podcast_id)
  end
end