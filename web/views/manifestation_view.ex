defmodule Pan.ManifestationView do
  use Pan.Web, :view

  def render("datatable.json", %{manifestations: manifestations}) do
    %{manifestations: Enum.map(manifestations, &manifestation_json/1)}
  end


  def manifestation_json(manifestation) do
    %{id:           manifestation.id,
      persona_id:   manifestation.persona_id,
      persona_name: manifestation.persona.name,
      user_id:      manifestation.user_id,
      user_name:    manifestation.user.name,
      actions:      datatable_actions(manifestation, &manifestation_path/3)}
  end
end
