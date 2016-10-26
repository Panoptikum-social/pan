defmodule Pan.Parser.Chapter do
  use Pan.Web, :controller

  def find_or_create(chapter_map, episode_id) do
    case Repo.get_by(Pan.Chapter, episode_id: episode_id,
                                  start:      chapter_map[:start]) do
      nil ->
        %Pan.Chapter{episode_id: episode_id}
        |> Map.merge(chapter_map)
        |> Repo.insert()
      chapter ->
        {:ok, chapter}
    end
  end
end