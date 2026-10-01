defmodule Pan.Repo.Migrations.AddOpenForCurationToCategoriesPodcasts do
  use Ecto.Migration

  # Existing rows start closed, every row added from now on starts open.
  def change do
    alter table(:categories_podcasts) do
      add(:open_for_curation, :boolean, default: false, null: false)
    end

    alter table(:categories_podcasts) do
      modify(:open_for_curation, :boolean,
        default: true,
        null: false,
        from: {:boolean, default: false, null: false}
      )
    end
  end
end
