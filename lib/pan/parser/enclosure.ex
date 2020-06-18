defmodule Pan.Parser.Enclosure do
  alias Pan.Repo

  def get_or_insert(enclosure_map, episode_id) do
    case get_enclosure(episode_id, enclosure_map) do
      nil ->
        %PanWeb.Enclosure{episode_id: episode_id}
        |> Map.merge(enclosure_map)
        |> Repo.insert()

      chapter ->
        {:ok, chapter}
    end
  end

  defp get_enclosure(episode_id, enclosure_map) do
    Repo.get_by(PanWeb.Enclosure,
      episode_id: episode_id,
      url: enclosure_map[:url]
    ) ||
      if enclosure_map[:guid] do
        Repo.get_by(PanWeb.Enclosure,
          episode_id: episode_id,
          guid: enclosure_map[:guid]
        )
      end
  end
end
