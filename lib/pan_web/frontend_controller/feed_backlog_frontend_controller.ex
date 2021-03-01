defmodule PanWeb.FeedBacklogFrontendController do
  use PanWeb, :controller
  alias PanWeb.FeedBacklog

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def new(conn, _params, _user) do
    changeset = FeedBacklog.changeset(%FeedBacklog{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"feed_backlog" => feed_backlog_params}, user) do
    changeset =
      FeedBacklog.changeset(%FeedBacklog{}, %{user_id: user.id, url: feed_backlog_params["url"]})

    case Repo.insert(changeset) do
      {:ok, _feed_backlog} ->
        conn
        |> put_flash(:info, "Your feed suggestion has been uploaded, it will be processed asap.")
        |> redirect(to: feed_backlog_frontend_path(conn, :new))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
