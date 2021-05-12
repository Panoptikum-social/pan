defmodule Pan.Repo.Migrations.RenameElasticToFullText do
  use Ecto.Migration

  def change do
    rename table(:podcasts), :elastic, to: :full_text
    rename table(:episodes), :elastic, to: :full_text
    rename table(:personas), :elastic, to: :full_text
    rename table(:chapters), :elastic, to: :full_text
    alter table(:users) do
      remove :elastic
    end
  end
end
