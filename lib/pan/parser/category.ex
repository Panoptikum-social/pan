defmodule Pan.Parser.Category do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Category


  def get_or_create_by(title, nil) do
    category = Repo.one(from c in Category, where: c.title == ^title and is_nil(c.parent_id))
    unless category, do: Repo.insert(%Category{title: title})

    category or Repo.one(from c in Category, where: c.title == ^title and is_nil(c.parent_id))
  end


  def get_or_create_by(title, parent_id) do
    category = Repo.get_by(Category, title: title, parent_id: parent_id)
    unless catogory, do: Repo.insert(%Category{title: title, parent_id: parent_id})

    category or Repo.get_by(Category, title: title, parent_id: parent_id)
  end
end