defmodule PanWeb.Api.Helpers do
  alias PanWeb.Api.ErrorView
  import Phoenix.Controller, only: [put_view: 2, render: 2, render: 3]
  import Plug.Conn, only: [put_status: 2, halt: 1]

  def send_404(conn) do
    conn
    |> put_view(ErrorView)
    |> put_status(404)
    |> render("404.json-api")
    |> halt()
  end


  def send_401(conn, reason) do
    conn
    |> put_view(ErrorView)
    |> put_status(401)
    |> render(:errors, data: %{code: 401,
                               status: 401,
                               title: "Unauthorized",
                               detail: reason})
    |> halt()
  end


  def send_error(conn, code, title, detail) do
    conn
    |> put_view(ErrorView)
    |> put_status(code)
    |> render(:errors, data: %{code: code,
                               status: code,
                               title: title,
                               detail: detail})
    |> halt()
  end

  def pagination_links(base_url, {page, size, total_pages}, conn) do
    %{number: page,
      size: size,
      total: total_pages,
      base_url: base_url}
    |> JaSerializer.Builder.PaginationLinks.build(conn)
  end
end
