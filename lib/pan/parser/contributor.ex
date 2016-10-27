defmodule Pan.Parser.Contributor do
  use Pan.Web, :controller

  def find_or_create(contributor_map) do
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
    contributors =
      Enum.map contributors_map, fn({_, contributor_map}) ->
        elem(find_or_create(contributor_map), 1)
      end

    Repo.preload(instance, :contributors)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:contributors, contributors)
    |> Repo.update!
  end
end