defmodule PanWeb.Api.PersonaView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location :location
  attributes [:pid, :name, :uri, :email, :description, :long_description, :orig_image_url, :image_title]

  has_one :redirect, serializer: PanWeb.Api.PlainPersonaView, include: false
  has_many :delegates, serializer: PanWeb.Api.PlainPersonaView, include: false

  has_many :engagements, serializer: PanWeb.Api.PlainEngagmentView, include: false
  has_many :podcasts, serializer: PanWeb.Api.PlainPodcastView, include: false
  has_many :gigs, serializer: PanWeb.Api.PlainGigView, include: false
  has_many :episodes, serializer: PanWeb.Api.PlainEpisodeView, include: false

  def location(persona, conn) do
    api_persona_url(conn, :show, persona)
  end

  def orig_image_url(persona, _conn) do
    persona.image_url
  end
end


defmodule PanWeb.Api.PlainPersonaView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location :location
  attributes [:pid, :name, :uri, :email, :description, :long_description, :orig_image_url, :image_title]

  def location(persona, conn) do
    api_persona_url(conn, :show, persona)
  end

  def orig_image_url(persona, _conn) do
    persona.image_url
  end
end