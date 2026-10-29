defmodule Pan.Repo.Migrations.AddIconAndColorToCategories do
  use Ecto.Migration

  # A Tabler icon name (priv/icons/tabler) per category and a Catppuccin
  # accent name per top level category, subcategories use their parent's
  # color. Set in the admin, see backlog.md #439.
  def change do
    alter table(:categories) do
      add(:icon, :string)
      add(:color, :string)
    end
  end
end
