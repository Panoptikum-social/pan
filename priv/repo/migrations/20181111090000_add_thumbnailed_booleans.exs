defmodule Pan.Repo.Migrations.AddElasticBooleans do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add :thumbnailed, :boolean
    end

    alter table(:episodes) do
      add :thumbnailed, :boolean
    end

    alter table(:podcasts) do
      add :thumbnailed, :boolean
    end

#    create index(:episodes, [:thumbnailed, :image_url],
#                            where: "thumbnailed IS NOT TRUE AND image_url IS NIL",
#                            name: :episodes_not_thumbnailed)

  end
end
