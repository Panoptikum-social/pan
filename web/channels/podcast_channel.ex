defmodule Pan.PodcastChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Podcast

  def join("podcasts:" <> podcast_id, _params, socket) do
    {:ok, assign(socket, :podcast_id, String.to_integer(podcast_id))}
  end

  def handle_in("like", params, socket) do
    broadcast! socket, "like", %{
      enjoyer: Repo.get!(User,    String.to_integer(params["enjoyer_id"])).name,
      podcast: Repo.get!(Podcast, String.to_integer(params["podcast_id"])).title
    }

    {:reply, :ok, socket}
  end
end