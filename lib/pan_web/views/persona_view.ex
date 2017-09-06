defmodule PanWeb.PersonaView do
  use Pan.Web, :view

  def render("datatable.json", %{personas: personas}) do
    %{personas: Enum.map(personas, &persona_json/1)}
  end


  def persona_json(persona) do
    %{id:          persona.id,
      pid:         "<nobr>" <> persona.pid <> "</nobr>",
      name:        "<nobr>" <> truncate(persona.name, 100) <> "</nobr>",
      uri:         persona.uri,
      email:       persona.email,
      description: persona.description,
      image_url:   persona.image_url,
      image_title: persona.image_title,
      actions:     datatable_actions(persona, &persona_path/3)}
  end
end
