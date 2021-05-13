defmodule Pan.Search.Episode do
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.Episode
  require Logger

  def batch_index do
    Pan.Search.batch_index(
      model: Episode,
      preloads: [podcast: [:languages, :categories]],
      selects: [
        :id,
        :title,
        :subtitle,
        :description,
        :summary,
        :shownotes,
        :inserted_at,
        :podcast_id,
        podcast: [:id, languages: :id, categories: :id]
      ],
      struct_function: &manticore_struct/1
    )
  end

  def manticore_struct(episode) do
    %{
      insert: %{
        index: "episodes",
        id: episode.id,
        doc: %{
          title: episode.title || "",
          subtitle: episode.subtitle || "",
          description: episode.description || "",
          summary: episode.summary || "",
          shownotes: episode.shownotes || "",
          inserted_at: to_unix(episode.inserted_at),
          podcast_id: episode.podcast.id || 0,
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
