defmodule Pan.MessageView do
  use Pan.Web, :view

  def render("datatable.json", %{messages: messages}) do
    %{messages: Enum.map(messages, &message_json/1)}
  end


  def message_json(message) do
    %{id:           message.id,
      type:         message.type,
      creator_id:   message.creator_id,
      creator_name: message.creator && "<nobr>" <> message.creator.name <> "</nobr>",
      persona_id:   message.persona_id,
      persona_name: message.persona && message.persona.name,
      content:      message.content,
      date:         "<nobr>" <> Timex.format!(message.inserted_at, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}") <> "</nobr>",
      topic:        message.topic,
      subtopic:     message.subtopic,
      event:        message.event,
      actions:      datatable_actions(message, &message_path/3)}
  end
end
