defmodule Pan.EngagementController do
  use Pan.Web, :controller

  alias Pan.Engagement


  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, _params) do
    engagements = from(Engagement, preload: [:persona, :podcast])
                  |> Repo.all()
    render conn, "datatable.json", engagements: engagements
  end

  def new(conn, _params) do
    changeset = Engagement.changeset(%Engagement{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"engagement" => engagement_params}) do
    changeset = Engagement.changeset(%Engagement{}, engagement_params)

    case Repo.insert(changeset) do
      {:ok, _engagement} ->
        conn
        |> put_flash(:info, "Engagement created successfully.")
        |> redirect(to: engagement_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    engagement = Repo.get!(Engagement, id)
    render(conn, "show.html", engagement: engagement)
  end

  def edit(conn, %{"id" => id}) do
    engagement = Repo.get!(Engagement, id)
    changeset = Engagement.changeset(engagement)
    render(conn, "edit.html", engagement: engagement, changeset: changeset)
  end

  def update(conn, %{"id" => id, "engagement" => engagement_params}) do
    engagement = Repo.get!(Engagement, id)
    changeset = Engagement.changeset(engagement, engagement_params)

    case Repo.update(changeset) do
      {:ok, engagement} ->
        conn
        |> put_flash(:info, "Engagement updated successfully.")
        |> redirect(to: engagement_path(conn, :show, engagement))
      {:error, changeset} ->
        render(conn, "edit.html", engagement: engagement, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    engagement = Repo.get!(Engagement, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(engagement)

    conn
    |> put_flash(:info, "Engagement deleted successfully.")
    |> redirect(to: engagement_path(conn, :index))
  end
end
