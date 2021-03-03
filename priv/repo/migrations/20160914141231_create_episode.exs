defmodule Pan.Repo.Migrations.CreateEpisode do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add(:title, :string)
      add(:link, :string)
      add(:publishing_date, :datetime)
      add(:guid, :string)
      add(:description, :text)
      add(:shownotes, :text)
      add(:payment_link_title, :string)
      add(:payment_link_url, :string)
      add(:deep_link, :string)
      add(:duration, :string)
      add(:author, :string)
      add(:subtitle, :string)
      add(:summary, :text)
      add(:podcast_id, references(:podcasts, on_delete: :nothing))

      timestamps()
    end

    create(index(:episodes, [:podcast_id]))
    create(unique_index(:episodes, [:guid]))
  end
end
