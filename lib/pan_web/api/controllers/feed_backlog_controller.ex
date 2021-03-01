defmodule PanWeb.Api.FeedBacklogController do
  use PanWeb, :controller
  alias PanWeb.{Api.Helpers, FeedBacklog}
  use JaSerializer

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, user) do
    feed_backlog =
      from(f in FeedBacklog,
        where:
          f.user_id == ^user.id and
            f.id == ^id,
        limit: 1,
        preload: :user
      )
      |> Repo.all()

    if feed_backlog != [] do
      render(conn, "show.json-api",
        data: feed_backlog,
        opts: [include: "user"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def create(conn, %{"url" => url}, user) do
    changeset =
      %FeedBacklog{user_id: user.id, url: url}
      |> FeedBacklog.changeset()

    case Repo.insert(changeset) do
      {:ok, feed_backlog} ->
        feed_backlog = Repo.preload(feed_backlog, :user)

        conn
        |> render("show.json-api",
          data: feed_backlog,
          opts: [include: "user"]
        )

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render(:errors, data: changeset)
    end
  end
end
