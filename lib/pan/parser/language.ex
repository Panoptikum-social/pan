defmodule Pan.Parser.Language do
  use Pan.Web, :controller

  def get_or_insert(language_map) do
    case Repo.get_by(PanWeb.Language, shortcode: language_map[:shortcode]) do
      nil ->
        %PanWeb.Language{shortcode: language_map[:shortcode],
                      name: UUID.uuid1(),
                      emoji: "_ is missing"}
        |> Repo.insert
      language ->
        {:ok, language}
    end
  end


  def persist_many(languages_map, podcast) do
    if languages_map do
      languages =
        Enum.map languages_map, fn({_, language_map}) ->
          elem(get_or_insert(language_map), 1)
        end

      podcast = Repo.preload(podcast, :languages)

      Ecto.Changeset.change(podcast)
      |> Ecto.Changeset.put_assoc(:languages, podcast.languages ++ Enum.uniq(languages))
      |> Repo.update!
    end
  end


  def delete_for_podcast(podcast_id) do
    (from lp in "languages_podcasts", where: lp.podcast_id == ^podcast_id)
    |> Repo.delete_all()
  end
end