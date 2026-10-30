defmodule PanWeb.CommunityTest do
  use Pan.DataCase, async: true

  alias PanWeb.{Category, Community}

  test "the slug is made from the title and follows a rename" do
    category = Repo.insert!(%Category{title: "Community slug #{System.unique_integer()}"})

    community =
      %Community{}
      |> Community.changeset(%{title: "Podcasterei.at", category_id: category.id})
      |> Repo.insert!()

    assert community.slug == "podcasterei-at"
    assert Phoenix.Param.to_param(community) == "podcasterei-at"

    community = community |> Community.changeset(%{title: "Frauenstimmen"}) |> Repo.update!()
    assert community.slug == "frauenstimmen"
  end
end
