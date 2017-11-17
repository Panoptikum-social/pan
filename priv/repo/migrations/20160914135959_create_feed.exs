defmodule Pan.Repo.Migrations.CreateFeed do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :self_link_title, :string
      add :self_link_url, :string
      add :next_page_url, :string
      add :prev_page_url, :string
      add :first_page_url, :string
      add :last_page_url, :string
      add :hub_link_url, :string
      add :feed_generator, :string
      add :podcast_id, references(:podcasts, on_delete: :nothing)

      timestamps()
    end
    create index(:feeds, [:podcast_id])

  end
end
