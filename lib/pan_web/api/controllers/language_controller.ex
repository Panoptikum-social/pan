defmodule PanWeb.Api.LanguageController do
  use Pan.Web, :controller
  alias PanWeb.{Api.Helpers, Language}
  use JaSerializer

  def index(conn, _params) do
    languages = Repo.all(Language)

    render conn, "index.json-api", data: languages
  end


  def show(conn, %{"id" => id}) do
    language = Repo.get(Language, id)

    if language do
      render conn, "show.json-api", data: language
    else
      Helpers.send_404(conn)
    end
  end
end
