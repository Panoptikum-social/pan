defmodule PanWeb.PersonaApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location :persona_api_url
  attributes [:pid, :name, :uri, :email, :description, :long_description, :image_url, :image_title]

  has_one :redirect, serializer: PanWeb.PlainPersonaApiView, include: true
  has_many :delegates, serializer: PanWeb.PlainPersonaApiView, include: true

  has_many :engagements, serializer: PanWeb.PlainEngagmentApiView, include: false
  has_many :podcasts, serializer: PanWeb.PlainPodcastApiView, include: false
  has_many :gigs, serializer: PanWeb.PlainGigApiView, include: false
  has_many :episodes, serializer: PanWeb.PlainEpisodeApiView, include: false

  def persona_api_url(persona, conn) do
    persona_api_url(conn, :show, persona)
  end
end


defmodule PanWeb.PlainPersonaApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location :persona_api_url
  attributes [:pid, :name, :uri, :email, :description, :long_description, :image_url, :image_title]

  def persona_api_url(persona, conn) do
    persona_api_url(conn, :show, persona)
  end
end