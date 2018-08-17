defmodule Pan.Updater.Podcast do
  alias Pan.Repo
  alias PanWeb.{Endpoint, Podcast}

  def import_new_episodes(podcast_id, current_user \\ nil) do
    set_next_update(podcast_id)
    {status, message} = Pan.Parser.Podcast.delta_import(podcast_id)

    if current_user do
      Repo.get(Podcast, podcast_id)
      |> build_notification({status, message}, current_user)
      |> broadcast(current_user)
    end
  end

  defp set_next_update(podcast_id) do
    podcast = Repo.get(Podcast, podcast_id)
    next_update = Timex.shift(Timex.now(), hours: podcast.update_intervall + 1)

    Podcast.changeset(podcast, %{
      update_intervall: podcast.update_intervall + 1,
      next_update: next_update
    })
    |> Repo.update()
  end

  defp build_notification(podcast, {:ok, _}, current_user) do
    %{
      content:
        "<i class='fa fa-refresh'></i> #{podcast.id} " <>
          "<i class='fa fa-podcast'></i> #{podcast.title}",
      type: "success",
      user_name: current_user && current_user.name
    }
  end

  defp build_notification(podcast, {:error, message}, current_user) do
    %{
      content:
        "Error: #{message} | <i class='fa fa-refresh'></i> #{podcast.id} " <>
          "<i class='fa fa-podcast'></i> {podcast.title}",
      type: "danger",
      user_name: current_user && current_user.name
    }
  end

  defp broadcast(notification, current_user) do
    Endpoint.broadcast("mailboxes:#{current_user.id}", "notification", notification)
  end
end
