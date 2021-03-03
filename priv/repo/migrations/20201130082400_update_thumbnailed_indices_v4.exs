defmodule Pan.Repo.Migrations.UpdateThumbnailedIndices do
  use Ecto.Migration

  def change do
    drop(index(:podcasts, [:id], name: :podcasts_not_thumbnailed_v3))
    drop(index(:personas, [:id], name: :personas_not_thumbnailed_v3))
    drop(index(:episodes, [:id], name: :episodes_not_thumbnailed_v3))

    create(
      index(:podcasts, [:id],
        where: "NOT thumbnailed AND NOT (image_url IS NULL)",
        name: :podcasts_not_thumbnailed_v4
      )
    )

    create(
      index(:personas, [:id],
        where: "NOT thumbnailed AND NOT (image_url IS NULL)",
        name: :personas_not_thumbnailed_v4
      )
    )

    create(
      index(:episodes, [:id],
        where: "NOT thumbnailed AND NOT (image_url IS NULL)",
        name: :episodes_not_thumbnailed_v4
      )
    )
  end
end
