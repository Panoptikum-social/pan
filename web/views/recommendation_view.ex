defmodule Pan.RecommendationView do
  use Pan.Web, :view

  def render("datatable.json", %{recommendations: recommendations}) do
    %{recommendations: Enum.map(recommendations, &recommendation_json/1)}
  end

  def recommendation_json(recommendation) do
    %{id:            recommendation.id,
      inserted_at:   "<nobr>" <> Timex.format!(recommendation.inserted_at, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}") <> "</nobr>",
      user_id:       recommendation.user_id,
      user_name:     recommendation.user.name,
      podcast_id:    recommendation.podcast_id,
      podcast_title: recommendation.podcast && recommendation.podcast.title,
      episode_id:    recommendation.episode_id,
      episode_title: recommendation.episode && recommendation.episode.title,
      chapter_id:    recommendation.chapter_id,
      chapter_title: recommendation.chapter && recommendation.chapter.title,
      comment:       recommendation.comment,
      actions:       datatable_actions(recommendation, &recommendation_path/3)}
  end
end
