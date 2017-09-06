defmodule Pan.FeedTest do
  use Pan.ModelCase

  alias PanWeb.Feed

  @valid_attrs %{feed_generator: "Feed generator",
                 first_page_url: "https://panoptikum.io/feed/first_page",
                 hub_link_url: "https://panoptikum.io/feed/hub_link",
                 last_page_url: "https://panoptikum.io/feed/last_page",
                 next_page_url: "https://panoptikum.io/feed/next_page",
                 prev_page_url: "https://panoptikum.io/feed/prev_page",
                 self_link_title: "Feed self link title",
                 self_link_url: "https://panoptikum.io/feed/self_link"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Feed.changeset(%Feed{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Feed.changeset(%Feed{}, @invalid_attrs)
    refute changeset.valid?
  end
end
