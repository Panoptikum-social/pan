defmodule Pan.DelegationController do
  use Pan.Web, :controller

  alias Pan.Delegation

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def datatable(conn, _params) do
    delegations = from(Delegation, preload: [:persona, :delegate])
                     |> Repo.all()
    render conn, "datatable.json", delegations: delegations
  end

  def new(conn, _params) do
    changeset = Delegation.changeset(%Delegation{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"delegation" => delegation_params}) do
    changeset = Delegation.changeset(%Delegation{}, delegation_params)

    case Repo.insert(changeset) do
      {:ok, _delegation} ->
        conn
        |> put_flash(:info, "Delegation created successfully.")
        |> redirect(to: delegation_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    delegation = Repo.get!(Delegation, id)
    render(conn, "show.html", delegation: delegation)
  end

  def edit(conn, %{"id" => id}) do
    delegation = Repo.get!(Delegation, id)
    changeset = Delegation.changeset(delegation)
    render(conn, "edit.html", delegation: delegation, changeset: changeset)
  end

  def update(conn, %{"id" => id, "delegation" => delegation_params}) do
    delegation = Repo.get!(Delegation, id)
    changeset = Delegation.changeset(delegation, delegation_params)

    case Repo.update(changeset) do
      {:ok, delegation} ->
        conn
        |> put_flash(:info, "Delegation updated successfully.")
        |> redirect(to: delegation_path(conn, :show, delegation))
      {:error, changeset} ->
        render(conn, "edit.html", delegation: delegation, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    delegation = Repo.get!(Delegation, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(delegation)

    conn
    |> put_flash(:info, "Delegation deleted successfully.")
    |> redirect(to: delegation_path(conn, :index))
  end
end
