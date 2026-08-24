defmodule Pan.Repo.Migrations.CreateJournals do
  use Ecto.Migration

  def change do
    create table(:journals) do
      # what ran: the module/function that made a change, so an entry can
      # be traced back to the code responsible (e.g. for a maintenance
      # backfill run from the admin panel)
      add(:module, :string)
      add(:method, :string)

      # what happened, in prose
      add(:text, :text)

      # optional before/after snapshots (e.g. a sample record, or a count),
      # for entries where showing the actual change matters more than
      # describing it
      add(:before, :text)
      add(:after, :text)

      timestamps(updated_at: false)
    end

    create(index(:journals, [:inserted_at]))
  end
end
