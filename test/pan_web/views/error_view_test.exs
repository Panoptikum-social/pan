defmodule PanWeb.ErrorViewTest do
  use PanWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html for an unmatched route", %{conn: conn} do
    # not_found.html renders the full site chrome (nav/head), which reaches
    # into @conn's verified-routes/router context via Routes.static_path and
    # similar - real request state that render_to_string can't fake with a
    # hand-built conn (tried; broke deeper each layer: missing :conn key,
    # then missing phoenix_format/phoenix_view, then missing router state
    # for VerifiedRoutes). A real request through the endpoint sets all of
    # that up itself via config.exs's `render_errors: [view: PanWeb.ErrorView,
    # ...]`, so let it.
    #
    # Also: a single path segment would match the persona catch-all
    # (`live("/:pid", Live.Persona.Show, ...)`), which 200s with its own
    # "not found" UI rather than a real 404 - need something with no
    # matching route pattern at all to hit RenderErrors for real.
    conn = get(conn, "/this/path/does/not/exist")

    assert conn.status == 404
    assert response(conn, 404) =~ "This url makes no sense for us."
  end

  test "renders 500.html" do
    assert render_to_string(PanWeb.ErrorView, "500.html", []) == "Server internal error"
  end
end
