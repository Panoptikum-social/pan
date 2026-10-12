defmodule Pan.Search.PersonaStructTest do
  use ExUnit.Case, async: true

  alias Pan.Search.Persona

  # A merge running while the push job loads a batch can leave an engagement
  # pointing to the podcast it just deleted.
  test "an engagement whose podcast is gone is left out of the persona doc" do
    persona = %{
      id: 1,
      redirect_id: nil,
      name: "Tim",
      pid: "tim",
      uri: nil,
      description: nil,
      long_description: nil,
      image_title: nil,
      thumbnails: [],
      podcasts: [],
      episodes: [],
      engagements: [
        %{podcast: nil, podcast_id: 5, role: "host"},
        %{podcast: %{title: "Freak Show"}, podcast_id: 1, role: "author"}
      ]
    }

    %{replace: %{doc: doc}} = Persona.manticore_struct(persona)

    assert Jason.decode!(doc.engagements) == [
             %{"podcast_title" => "Freak Show", "podcast_id" => 1, "role" => "author"}
           ]
  end
end
