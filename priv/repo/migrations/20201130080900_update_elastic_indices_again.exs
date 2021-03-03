defmodule Pan.Repo.Migrations.UpdateElasticIndicesAgain do
  use Ecto.Migration

  def change do
    drop(index(:episodes, [:elastic], name: :episodes_missing_from_elasticsearch_v3))
    drop(index(:users, [:elastic], name: :users_missing_from_elasticsearch_v3))
    drop(index(:personas, [:elastic], name: :personas_missing_from_elasticsearch_v3))
    drop(index(:podcasts, [:elastic], name: :podcasts_missing_from_elasticsearch_v3))

    create(
      index(:episodes, [:elastic],
        where: "NOT elastic",
        name: :episodes_missing_from_elasticsearch_v4
      )
    )

    create(
      index(:users, [:elastic],
        where: "NOT elastic",
        name: :users_missing_from_elasticsearch_v4
      )
    )

    create(
      index(:personas, [:elastic],
        where: "NOT elastic",
        name: :personas_missing_from_elasticsearch_v4
      )
    )

    create(
      index(:podcasts, [:elastic],
        where: "NOT elastic",
        name: :podcasts_missing_from_elasticsearch_v4
      )
    )
  end
end
