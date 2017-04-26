defmodule Pan.LanguageController do
  use Pan.Web, :controller

  alias Pan.Language
  alias Pan.Podcast

  plug :scrub_params, "language" when action in [:create, :update]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, _params) do
    languages = Repo.all(Language)
    render conn, "datatable.json", languages: languages
  end

  def new(conn, _params) do
    changeset = Language.changeset(%Language{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"language" => language_params}) do
    changeset = Language.changeset(%Language{}, language_params)

    case Repo.insert(changeset) do
      {:ok, _language} ->
        conn
        |> put_flash(:info, "Language created successfully.")
        |> redirect(to: language_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    language = Repo.get!(Language, id)
               |> Repo.preload(podcasts: from(Podcast, limit: 10))
    render(conn, "show.html", language: language)
  end

  def edit(conn, %{"id" => id}) do
    language = Repo.get!(Language, id)
    changeset = Language.changeset(language)
    render(conn, "edit.html", language: language, changeset: changeset)
  end

  def update(conn, %{"id" => id, "language" => language_params}) do
    language = Repo.get!(Language, id)
    changeset = Language.changeset(language, language_params)

    case Repo.update(changeset) do
      {:ok, language} ->
        conn
        |> put_flash(:info, "Language updated successfully.")
        |> redirect(to: language_path(conn, :show, language))
      {:error, changeset} ->
        render(conn, "edit.html", language: language, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    language = Repo.get!(Language, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(language)

    conn
    |> put_flash(:info, "Language deleted successfully.")
    |> redirect(to: language_path(conn, :index))
  end
end
