defmodule Pan.Search.Episode do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.Episode
  require Logger

  def batch_index do
    Pan.Search.batch_index(
      model: Episode,
      preloads: [:languages, :categories, :podcasts],
      selects: [
        :id,
        :title,
        :subtitle,
        :description,
        :summary,
        :shownotes,
        :created_at,
        podcast: [:id, languages: :id, categories: :id],
        languages: :id,
        categories: :id
      ]
    )
  end

  def manticore_struct(episode) do
    %{
      insert: %{
        index: "episodes",
        id: episode.id,
        doc: %{
          title: episode.title,
          subtitle: episode.subtitle,
          description: episode.description,
          summary: episode.summary,
          shownotes: episode.shownotes,
          created_at: to_unix(episode.created_at),
          podcast_ids: Enum.map(episode.podcasts, & &1.id),
          language_ids: Enum.map(episode.podcast.languages, & &1.id),
          category_ids: Enum.map(episode.podcast.categories, & &1.id)
        }
      }
    }
  end

  defp to_unix(naive) do
    {:ok, date_time} = DateTime.from_naive(naive, "Etc/UTC")
    DateTime.to_unix(date_time)
  end

  def batch_reset do
    Logger.info("=== full_text reset up to 10_000 episodes ===")

    episode_ids =
      from(e in Episode,
        where: e.full_text == true,
        select: e.id,
        limit: 10_000
      )
      |> Repo.all()

    from(e in Episode, where: e.id in ^episode_ids)
    |> Repo.update_all(set: [full_text: false])

    if length(episode_ids) > 0, do: batch_reset()
  end
end
