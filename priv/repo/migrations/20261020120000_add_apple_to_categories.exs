defmodule Pan.Repo.Migrations.AddAppleToCategories do
  use Ecto.Migration

  # Marks the categories of Apple Podcasts' current list, the target of the
  # category clean-up. Set from the merge page ("Update Apple flags", see
  # Pan.AppleCategories) or in the admin grid.
  def change do
    alter table(:categories) do
      add(:apple, :boolean, default: false, null: false)
    end
  end
end
