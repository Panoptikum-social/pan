defmodule Pan.PodcastFrontendView do
  use Pan.Web, :view

  def panel_cycle(counter) do
    Enum.at(["panel-default", "panel-info", "panel-danger",
             "panel-warning", "panel-primary", "panel-success"], rem(counter, 6))
  end

  def likes?(user, podcast) do
    Pan.Repo.get_by(Pan.Like, enjoyer_id: user.id,
                              podcast_id: podcast.id)
  end
end
