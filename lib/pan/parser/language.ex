defmodule Pan.Parser.Language do
  use Pan.Web, :controller

  def find_or_create(shortcode) do
    case Repo.get_by(Pan.Language, shortcode: shortcode) do
      nil -> %Pan.Language{shortcode: shortcode,
                           name: UUID.uuid1()}
             |> Repo.insert
      language -> {:ok, language}
    end
  end


  def persist_many(languages_map, podcast) do
    languages =
      Enum.map languages_map, fn({_, language_map}) ->
        elem(find_or_create(language_map), 1)
      end

    Repo.preload(podcast, :languages)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:languages, languages)
    |> Repo.update!
  end
end