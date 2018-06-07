defmodule PanWeb.UserJsonDownloadView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  attributes [:name, :username, :email, :admin, :podcaster, :email_confirmed, :share_subscriptions,
              :share_follows, :pro_until, :billing_address, :payment_reference, :paper_bill]

  has_many :personas, serializer: PanWeb.Api.PlainPersonaView, include: true
  has_many :opmls, serializer: PanWeb.Api.PlainOpmlView, include: true
  has_many :invoices, serializer: PanWeb.Api.InvoiceView, include: true

  has_many :podcasts_i_subscribed, serializer: PanWeb.Api.PlainPodcastView, include: true
  has_many :podcasts_i_follow, serializer: PanWeb.Api.PlainPodcastView, include: true
  has_many :podcasts_i_like, serializer: PanWeb.Api.PlainPodcastView, include: true
  has_many :episodes_i_like, serializer: PanWeb.Api.PlainEpisodeView, include: true
  has_many :chapters_i_like, serializer: PanWeb.Api.PlainChapterView, include: true

  has_many :users_i_like, serializer: PanWeb.Api.PlainUserView, include: true
  has_many :users_i_follow, serializer: PanWeb.Api.PlainUserView, include: true

  has_many :personas_i_follow, serializer: PanWeb.Api.PlainPersonaView, include: true
  has_many :personas_i_like, serializer: PanWeb.Api.PlainPersonaView, include: true

  has_many :categories_i_follow, serializer: PanWeb.Api.PlainCategoryView, include: true
  has_many :categories_i_like, serializer: PanWeb.Api.PlainCategoryView, include: true

  has_many :messages_created, serializer: PanWeb.Api.PlainMessageView, include: true
  has_many :recommendations, serializer: PanWeb.Api.PlainRecommendationView, include: true
end
