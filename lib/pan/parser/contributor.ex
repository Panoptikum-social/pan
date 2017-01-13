defmodule Pan.Parser.Contributor do
  use Pan.Web, :controller

  def get_or_insert(contributor_map) do
    case Repo.get_by(Pan.Contributor, uri: contributor_map[:uri]) do
      nil ->
        %Pan.Contributor{}
        |> Map.merge(contributor_map)
        |> Repo.insert()
      contributor ->
        {:ok, contributor}
    end
  end


  def persist_many(contributors_map, instance) do
    if contributors_map do
      contributors =
        Enum.map contributors_map, fn({_, contributor_map}) ->
          elem(get_or_insert(contributor_map), 1)
        end

      Repo.preload(instance, :contributors)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:contributors, contributors)
      |> Repo.update!
    end
  end
end