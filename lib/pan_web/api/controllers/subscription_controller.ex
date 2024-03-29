defmodule PanWeb.Api.SubscriptionController do
  use PanWeb, :controller
  alias PanWeb.{Api.Helpers, Podcast, Subscription}
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, _user) do
    subscription =
      from(s in Subscription,
        join: u in assoc(s, :user),
        where: s.id == ^id and u.share_subscriptions == true,
        limit: 1,
        preload: [:user, :podcast]
      )
      |> Repo.all()

    if subscription != [] do
      render(conn, "show.json-api",
        data: subscription,
        opts: [include: "user,podcast"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"podcast_id" => podcast_id}, user) do
    case Repo.get(Podcast, podcast_id) do
      %PanWeb.Podcast{} ->
        {:ok, subscription} =
          podcast_id
          |> String.to_integer()
          |> Podcast.subscribe(user.id)

        subscription =
          subscription
          |> Repo.preload([:user, :podcast])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: subscription, opts: [include: "user,podcast"])

      nil ->
        Helpers.send_404(conn)
    end
  end
end
