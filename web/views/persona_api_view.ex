defmodule Pan.PersonaApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location :persona_api_url
  attributes [:pid, :name, :uri, :email, :description, :long_description, :image_url, :image_title]

  has_one :redirect, serializer: Pan.PlainPersonaApiView, include: true
  has_many :delegates, serializer: Pan.PlainPersonaApiView, include: true

  has_many :engagements, serializer: Pan.PlainEngagmentApiView, include: true
  # has_many gigs

  def persona_api_url(persona, conn) do
    persona_api_url(conn, :show, persona)
  end
end


defmodule Pan.PlainPersonaApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location :persona_api_url
  attributes [:pid, :name, :uri, :email, :description, :long_description, :image_url, :image_title]

  def persona_api_url(persona, conn) do
    persona_api_url(conn, :show, persona)
  end
end