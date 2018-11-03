defmodule Pan.Repo.Migrations.FixPartialIndicesForElasticsearch do
  use Ecto.Migration

  def change do
    drop index(:episodes, [:elastic], name: :episodes_missing_from_elasticsearch)
    drop index(:users, [:elastic], name: :users_missing_from_elasticsearch)
    drop index(:personas, [:elastic], name: :personas_missing_from_elasticsearch)
    drop index(:podcasts, [:elastic], name: :podcasts_missing_from_elasticsearch)

    create index(:episodes, [:elastic], where: "elastic IS NOT TRUE", name: :episodes_missing_from_elasticsearch)
    create index(:users, [:elastic], where: "elastic IS NOT TRUE", name: :users_missing_from_elasticsearch)
    create index(:personas, [:elastic], where: "elastic IS NOT TRUE", name: :personas_missing_from_elasticsearch)
    create index(:podcasts, [:elastic], where: "elastic IS NOT TRUE", name: :podcasts_missing_from_elasticsearch)
  end
end
