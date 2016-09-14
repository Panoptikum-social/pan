defmodule Pan.EpisodeTest do
  use Pan.ModelCase

  alias Pan.Episode

  @valid_attrs %{author: "some content", deep_link: "some content", description: "some content", duration: "some content", guid: "some content", link: "some content", payment_link_title: "some content", payment_link_url: "some content", publishing_date: "2010-04-17 14:00:00", shownotes: "some content", subtitle: "some content", summary: "some content", title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Episode.changeset(%Episode{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Episode.changeset(%Episode{}, @invalid_attrs)
    refute changeset.valid?
  end
end
