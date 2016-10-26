defmodule Pan.Parser.Enclosure do
  use Pan.Web, :controller

  def find_or_create(enclosure_map, episode_id) do
    case Repo.get_by(Pan.Enclosure, episode_id: episode_id,
                                    guid:       enclosure_map[:guid],
                                    url:        enclosure_map[:url]) do
      nil ->
        %Pan.Enclosure{episode_id: episode_id}
        |> Map.merge(enclosure_map)
        |> Repo.insert()
      chapter ->
        {:ok, chapter}
    end
  end
end