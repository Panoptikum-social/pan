defmodule PanWeb.Api.Helpers do
  alias PanWeb.Api.ErrorView
  import Phoenix.Controller, only: [put_view: 2, render: 2, render: 3]
  import Plug.Conn, only: [put_status: 2, halt: 1, put_private: 3]

  def send_404(conn) do
    conn
    |> put_view(ErrorView)
    |> put_status(404)
    |> render("404.json-api")
    |> halt()
  end

  # 504 for any failed feed download, not only timeouts: clients may rely on
  # the status, the reason is in the detail
  def send_504(conn, reason), do: send_error(conn, 504, "Feed download failed", reason)

  def send_401(conn, reason) do
    conn
    |> put_view(ErrorView)
    |> put_status(401)
    |> render(:errors, data: %{code: 401, status: 401, title: "Unauthorized", detail: reason})
    |> halt()
  end

  def send_error(conn, code, title, detail, meta \\ nil) do
    data = %{code: code, status: code, title: title, detail: detail}
    data = if meta, do: Map.put(data, :meta, meta), else: data

    conn
    # read by PanWeb.Api.PodcastController's error recording
    |> put_private(:api_error, data)
    |> put_view(ErrorView)
    |> put_status(code)
    |> render(:errors, data: data)
    |> halt()
  end

  def pagination_links(base_url, {page, size, total_pages}, conn) do
    %{number: page, size: size, total: total_pages, base_url: base_url}
    |> JaSerializer.Builder.PaginationLinks.build(conn)
  end

  def add_etag_header(conn, json) do
    md5_hash =
      :crypto.hash(:md5, json)
      |> Base.encode16()

    Plug.Conn.put_resp_header(conn, "ETag", md5_hash)
  end
end
