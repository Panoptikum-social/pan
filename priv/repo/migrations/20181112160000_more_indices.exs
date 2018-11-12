defmodule Pan.Repo.Migrations.MoreIndices do
  use Ecto.Migration

  def change do
    create index(:episodes, [:id, "publishing_date DESC NULLS LAST"])
  end
end