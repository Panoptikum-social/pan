defmodule Pan.ErrorViewTest do
  use PanWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  @tag :currently_broken # FIXME
  test "renders 404.html" do
    assert render_to_string(Pan.ErrorView, "404.html", conn: build_conn(:get, "/")) =~
      "This page could not be found!"
  end

  @tag :currently_broken # FIXME
  test "render 500.html" do
    assert render_to_string(Pan.ErrorView, "500.html", []) ==
           "Server internal error"
  end

  @tag :currently_broken # FIXME
  test "render any other" do
    assert render_to_string(Pan.ErrorView, "505.html", []) ==
           "Server internal error"
  end
end
