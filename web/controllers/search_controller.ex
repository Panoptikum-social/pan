defmodule Pan.SearchController do
  use Pan.Web, :controller
  alias Pan.Search

  def elasticsearch_push(conn, %{"hours" => hours}) do
    String.to_integer(hours)
    |> Search.push()

    render(conn, "done.html", %{})
  end
end