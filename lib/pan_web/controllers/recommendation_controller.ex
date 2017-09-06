defmodule PanWeb.RecommendationController do
  use Pan.Web, :controller
  alias PanWeb.Recommendation

  def index(conn, _params) do
    render(conn, "index.html")
  end


  def datatable(conn, _params) do
    recommendations = from(Recommendation, preload: [:user, :podcast, :episode, :chapter])
                      |> Repo.all()
    render conn, "datatable.json", recommendations: recommendations
  end


  def new(conn, _params) do
    changeset = Recommendation.changeset(%Recommendation{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"recommendation" => recommendation_params}) do
    changeset = Recommendation.changeset(%Recommendation{}, recommendation_params)

    case Repo.insert(changeset) do
      {:ok, _recommendation} ->
        conn
        |> put_flash(:info, "Recommendation created successfully.")
        |> redirect(to: recommendation_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    recommendation = Repo.get!(Recommendation, id)
    render(conn, "show.html", recommendation: recommendation)
  end


  def edit(conn, %{"id" => id}) do
    recommendation = Repo.get!(Recommendation, id)
    changeset = Recommendation.changeset(recommendation)
    render(conn, "edit.html", recommendation: recommendation, changeset: changeset)
  end


  def update(conn, %{"id" => id, "recommendation" => recommendation_params}) do
    recommendation = Repo.get!(Recommendation, id)
    changeset = Recommendation.changeset(recommendation, recommendation_params)

    case Repo.update(changeset) do
      {:ok, recommendation} ->
        conn
        |> put_flash(:info, "Recommendation updated successfully.")
        |> redirect(to: recommendation_path(conn, :show, recommendation))
      {:error, changeset} ->
        render(conn, "edit.html", recommendation: recommendation, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    recommendation = Repo.get!(Recommendation, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(recommendation)

    conn
    |> put_flash(:info, "Recommendation deleted successfully.")
    |> redirect(to: recommendation_path(conn, :index))
  end
end
