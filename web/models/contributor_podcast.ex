defmodule Pan.ContributorPodcast do
  use Pan.Web, :model

  @primary_key false

  schema "contributors_podcasts" do
    belongs_to :podcast, Pan.Podcast
    belongs_to :contributor, Pan.Contributor
  end
end