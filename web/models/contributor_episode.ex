defmodule Pan.ContributorEpisode do
  use Pan.Web, :model

  @primary_key false

  schema "contributors_episodes" do
    belongs_to :episode, Pan.Episode
    belongs_to :contributor, Pan.Contributor
  end
end