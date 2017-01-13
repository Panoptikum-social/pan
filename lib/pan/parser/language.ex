defmodule Pan.Parser.Language do
  use Pan.Web, :controller

  def get_or_insert(language_map) do
    case Repo.get_by(Pan.Language, shortcode: language_map[:shortcode]) do
      nil ->
        %Pan.Language{shortcode: language_map[:shortcode],
                      name: UUID.uuid1()}
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

      Repo.preload(podcast, :languages)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:languages, languages)
      |> Repo.update!
    end
  end
end