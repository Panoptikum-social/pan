defmodule Pan.Parser.Podcast do
  use Pan.Web, :controller
  alias Pan.Repo

  def find_or_create(podcast_map, owner_id) do
    case Repo.get_by(Pan.Podcast, title: podcast_map[:title]) do
      nil ->
        %Pan.Podcast{owner_id: owner_id}
        |> Map.merge(podcast_map)
        |> Repo.insert()
      podcast ->
        {:ok, podcast}
    end
  end

  def delta_import(id) do
    podcast = Repo.get!(Pan.Podcast, id)
  end
end