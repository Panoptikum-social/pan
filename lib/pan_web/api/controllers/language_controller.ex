defmodule PanWeb.Api.LanguageController do
  use Pan.Web, :controller
  alias PanWeb.Language
  use JaSerializer

  def index(conn, _params) do
    languages = Repo.all(Language)

    render conn, "index.json-api", data: languages
  end


  def show(conn, %{"id" => id}) do
    language = Repo.get(Language, id)

    render conn, "show.json-api", data: language
  end
end
