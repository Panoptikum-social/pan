defmodule Pan.PersonaApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location "https://panoptikum.io/jsonapi/personas/:id"
  attributes [:pid, :name, :uri, :email, :description, :long_description, :image_url, :image_title]

  has_one :redirect, serializer: Pan.PlainPersonaApiView, include: true
  has_many :delegates, serializer: Pan.PlainPersonaApiView, include: true

  has_many :engagements, serializer: Pan.PlainEngagmentApiView, include: true
  # has_many gigs
end


defmodule Pan.PlainPersonaApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "persona"

  location "https://panoptikum.io/jsonapi/personas/:id"
  attributes [:pid, :name, :uri, :email, :description, :long_description, :image_url, :image_title]
end