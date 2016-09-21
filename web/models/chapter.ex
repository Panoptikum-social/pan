defmodule Pan.Chapter do
  use Pan.Web, :model

  schema "chapters" do
    field :start, :string
    field :title, :string
    belongs_to :episode, Pan.Episode

    timestamps
  end

  @required_fields ~w(start title)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end


  def find_or_create(category) do
    query = from c in category,
            where: c.title == ^category.title
    if !Repo.one(query)  do
      Repo.insert(category)
    end
    Repo.one(query)
  end
end
