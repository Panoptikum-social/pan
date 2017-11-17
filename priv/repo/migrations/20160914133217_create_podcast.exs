defmodule Pan.Repo.Migrations.CreatePodcast do
  use Ecto.Migration

  def change do
    create table(:podcasts) do
      add :title, :string
      add :website, :string
      add :description, :text
      add :summary, :text
      add :image_title, :string
      add :image_url, :string
      add :last_build_date, :datetime
      add :payment_link_title, :string
      add :payment_link_url, :string
      add :author, :string
      add :explicit, :boolean, default: false
      add :unique_identifier, :uuid
      add :language_id, references(:languages, on_delete: :nothing)
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:podcasts, [:language_id])
    create index(:podcasts, [:owner_id])
    create unique_index(:podcasts, [:title])
    create unique_index(:podcasts, [:website])
  end
end
