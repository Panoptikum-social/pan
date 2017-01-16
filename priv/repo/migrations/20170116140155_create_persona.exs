defmodule Pan.Repo.Migrations.CreatePersona do
  use Ecto.Migration

  def change do
    create table(:personas) do
      add :pid, :string
      add :name, :string
      add :uri, :string
      add :email, :string
      add :description, :string
      add :image_url, :string
      add :image_title, :string

      timestamps()
    end

    create unique_index(:personas, [:pid])
    create unique_index(:personas, [:uri])
  end
end
