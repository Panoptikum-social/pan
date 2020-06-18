defmodule Pan.Repo.Migrations.CreateGig do
  use Ecto.Migration

  def change do
    create table(:gigs) do
      add(:from_in_s, :integer)
      add(:until_in_s, :integer)
      add(:comment, :string)
      add(:publishing_date, :datetime)
      add(:role, :string)
      add(:persona_id, references(:personas, on_delete: :nothing))
      add(:episode_id, references(:episodes, on_delete: :nothing))

      timestamps()
    end

    create(index(:gigs, [:persona_id]))
    create(index(:gigs, [:episode_id]))
  end
end
