defmodule PanWeb.PageLiveTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    # "Boilerplate Generator" was leftover from the phx.new scaffold and
    # never present on this app's actual home page - swapped for real,
    # always-present copy from home.ex
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Top 10 most liked Podcasts"
    assert render(page_live) =~ "Top 10 most liked Podcasts"
  end
end
