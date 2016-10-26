defmodule Pan.Parser.Category do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Category


  def find_or_create(title, nil) do
    category = Repo.one(from c in Category, where: c.title == ^title and is_nil(c.parent_id))
    unless category, do: Repo.insert(%Category{title: title})

    category || Repo.one(from c in Category, where: c.title == ^title and is_nil(c.parent_id))
  end


  def find_or_create(title, parent_id) do
    category = Repo.get_by(Category, title: title, parent_id: parent_id)
    unless category, do: Repo.insert(%Category{title: title, parent_id: parent_id})

    category || Repo.get_by(Category, title: title, parent_id: parent_id)
  end
end