defmodule PanWeb.Live.Home do
  use Surface.LiveView
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Surface.{Panel, TopList, Tab}
  use PanWeb, :controller
  alias PanWeb.Podcast

  def mount(_params, _session, socket) do
    popular_podcasts =
      from(p in Podcast,
        select: [p.subscriptions_count, p.id, p.title],
        order_by: [fragment("? DESC NULLS LAST", p.subscriptions_count)],
        limit: 15)
      |> Repo.all()

    liked_podcasts =
      from(p in Podcast,
        select: [p.likes_count, p.id, p.title],
        order_by: [fragment("? DESC NULLS LAST", p.likes_count)],
        limit: 10)
      |> Repo.all()

    {:ok, assign(socket, popular_podcasts: popular_podcasts,
                         liked_podcasts: liked_podcasts,
                         latest_podcasts: PanWeb.Podcast.latest())}
  end
end
