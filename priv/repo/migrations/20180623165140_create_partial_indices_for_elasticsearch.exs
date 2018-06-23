defmodule Pan.Repo.Migrations.CreatePartialIndicesForElasticsearch do
  use Ecto.Migration

  def change do
    create index(:episodes, [:elastic], where: "elastic != true", name: :episodes_missing_from_elasticsearch)
    create index(:users, [:elastic], where: "elastic != true", name: :users_missing_from_elasticsearch)
    create index(:personas, [:elastic], where: "elastic != true", name: :personas_missing_from_elasticsearch)
    create index(:podcasts, [:elastic], where: "elastic != true", name: :podcasts_missing_from_elasticsearch)
  end
end
