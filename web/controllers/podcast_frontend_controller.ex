defmodule Pan.PodcastFrontendController do
  use Pan.Web, :controller

  alias Pan.Podcast
  alias Pan.Episode


  def index(conn, _params) do
    podcasts = Repo.all(Podcast)
               |> Repo.preload(:categories)
    render(conn, "index.html", podcasts: podcasts)
  end


  def show(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    |> Repo.preload([:languages, :owner, :feeds, :followers])
    |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
    render(conn, "show.html", podcast: podcast)
  end

  def like(conn, %{"id" => id}) do
    if conn.assigns.current_user do
      podcast = Repo.get!(Podcast, id)
      |> Repo.preload([:languages, :owner, :feeds, :followers])
      |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
      podcast
      |> Ecto.Changeset.change
      |> Ecto.Changeset.put_assoc(:followers, [conn.assigns.current_user | podcast.followers])
      |> Repo.update!

      podcast = Repo.get!(Podcast, id)
      |> Repo.preload([:languages, :owner, :feeds, :followers])
      |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
      conn
      |> render("show.html", podcast: podcast)
    else
    end
  end

  def unlike(conn, %{"id" => id}) do
    if conn.assigns.current_user do
      podcast = Repo.get!(Podcast, id)
      |> Repo.preload([:languages, :owner, :feeds, :followers])
      |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))

      podcast
      |> Ecto.Changeset.change
      |> Ecto.Changeset.put_assoc(:followers, List.delete(podcast.followers, conn.assigns.current_user))
      |> Repo.update!

      podcast = Repo.get!(Podcast, id)
      |> Repo.preload([:languages, :owner, :feeds, :followers])
      |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
      conn
      |> render("show.html", podcast: podcast)
    else
    end
  end

  def subscribe_button(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    podcast = Repo.preload(podcast, :feeds)
    render(conn, "subscribe_button.html", podcast: podcast)
  end
end