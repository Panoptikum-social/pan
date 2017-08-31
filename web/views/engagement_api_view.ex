defmodule Pan.EngagementApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location "https://panoptikum.io/jsonapi/engagements/:id"
  attributes [:from, :until, :comment, :role, :persona_id]

  has_one :persona, serializer: Pan.PlainPersonaApiView, include: true
  has_one :podcast, serializer: Pan.ReducedPodcastApiView, include: true
end


defmodule Pan.PlainEngagmentApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location "https://panoptikum.io/jsonapi/engagements/:id"
  attributes [:from, :until, :comment, :role, :persona_id]
end