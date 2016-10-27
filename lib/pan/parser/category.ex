defmodule Pan.Parser.Category do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Category


  def find_or_create(title, nil) do
    case Repo.one(from c in Category, where: c.title == ^title and is_nil(c.parent_id)) do
      nil ->
        %Category{title: title}
        |> Repo.insert()
      category ->
        {:ok, category}
    end
  end

  def find_or_create(title, parent_id) do
    case Repo.get_by(Category, title: title, parent_id: parent_id) do
      nil ->
        %Category{title: title, parent_id: parent_id}
        |> Repo.insert()
      category ->
        {:ok, category}
    end
  end


  def assign_many(categories_map, podcast) do
    if categories_map do
      categories =
        Enum.map categories_map, fn({id, _}) ->
          Repo.get(Pan.Category, id)
        end

      Repo.preload(podcast, :categories)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:categories, categories)
      |> Repo.update!
    end
  end
end