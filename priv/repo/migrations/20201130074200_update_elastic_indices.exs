defmodule Pan.Repo.Migrations.UpdateElasticIndices do
  use Ecto.Migration

  def change do
    drop(index(:episodes, [:elastic], name: :episodes_missing_from_elasticsearch))
    drop(index(:users, [:elastic], name: :users_missing_from_elasticsearch))
    drop(index(:personas, [:elastic], name: :personas_missing_from_elasticsearch))
    drop(index(:podcasts, [:elastic], name: :podcasts_missing_from_elasticsearch))

    create(
      index(:episodes, [:elastic],
        where: "elastic IS FALSE",
        name: :episodes_missing_from_elasticsearch_v3
      )
    )

    create(
      index(:users, [:elastic],
        where: "elastic IS FALSE",
        name: :users_missing_from_elasticsearch_v3
      )
    )

    create(
      index(:personas, [:elastic],
        where: "elastic IS FALSE",
        name: :personas_missing_from_elasticsearch_v3
      )
    )

    create(
      index(:podcasts, [:elastic],
        where: "elastic IS FALSE",
        name: :podcasts_missing_from_elasticsearch_v3
      )
    )
  end
end
