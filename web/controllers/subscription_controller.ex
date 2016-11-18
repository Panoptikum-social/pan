defmodule Pan.SubscriptionController do
  use Pan.Web, :controller

  alias Pan.Subscription

  def index(conn, _params) do
    subscriptions = Repo.all(Subscription)
    render(conn, "index.html", subscriptions: subscriptions)
  end

  def new(conn, _params) do
    changeset = Subscription.changeset(%Subscription{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"subscription" => subscription_params}) do
    changeset = Subscription.changeset(%Subscription{}, subscription_params)

    case Repo.insert(changeset) do
      {:ok, _subscription} ->
        conn
        |> put_flash(:info, "Subscription created successfully.")
        |> redirect(to: subscription_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    subscription = Repo.get!(Subscription, id)
    render(conn, "show.html", subscription: subscription)
  end

  def edit(conn, %{"id" => id}) do
    subscription = Repo.get!(Subscription, id)
    changeset = Subscription.changeset(subscription)
    render(conn, "edit.html", subscription: subscription, changeset: changeset)
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    subscription = Repo.get!(Subscription, id)
    changeset = Subscription.changeset(subscription, subscription_params)

    case Repo.update(changeset) do
      {:ok, subscription} ->
        conn
        |> put_flash(:info, "Subscription updated successfully.")
        |> redirect(to: subscription_path(conn, :show, subscription))
      {:error, changeset} ->
        render(conn, "edit.html", subscription: subscription, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    subscription = Repo.get!(Subscription, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(subscription)

    conn
    |> put_flash(:info, "Subscription deleted successfully.")
    |> redirect(to: subscription_path(conn, :index))
  end
end
