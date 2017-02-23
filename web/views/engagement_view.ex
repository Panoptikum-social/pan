defmodule Pan.EngagementView do
  use Pan.Web, :view

  def render("datatable.json", %{engagements: engagements}) do
    %{engagements: Enum.map(engagements, &engagement_json/1)}
  end

  def engagement_json(engagement) do
    %{id:            engagement.id,
      persona_id:    engagement.persona_id,
      persona_name:  engagement.persona.name,
      podcast_id:    engagement.podcast_id,
      podcast_title: engagement.podcast.title,
      from:          engagement.from,
      until:         engagement.until,
      comment:       engagement.comment,
      role:          engagement.role,
      actions:       datatable_actions(engagement, &engagement_path/3)}
  end
end