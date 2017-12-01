defmodule Pan.Parser.Chapter do
  use Pan.Web, :controller
  alias Pan.Repo

  def get_or_insert(chapter_map, episode_id) do
    case Repo.get_by(PanWeb.Chapter, episode_id: episode_id,
                                  start:      chapter_map[:start]) do
      nil ->
        %PanWeb.Chapter{episode_id: episode_id}
        |> Map.merge(chapter_map)
        |> Repo.insert()
      chapter ->
        {:ok, chapter}
    end
  end


  def insert_or_touch(chapter_map, episode_id) do
    case Repo.get_by(PanWeb.Chapter, episode_id: episode_id,
                                     start: chapter_map[:start]) do
      nil ->
        %PanWeb.Chapter{episode_id: episode_id}
        |> Map.merge(chapter_map)
        |> Repo.insert()
      chapter ->
        chapter
        |> PanWeb.Chapter.changeset()
        |> Repo.update([force: true]) # updates timestamp
        {:ok, chapter}
    end
  end
end