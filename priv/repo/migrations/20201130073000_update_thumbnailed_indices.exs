defmodule Pan.Repo.Migrations.UpdateThumbnailedIndices do
  use Ecto.Migration

  def change do
    drop(index(:podcasts, [:id], name: :podcasts_not_thumbnailed))
    drop(index(:personas, [:id], name: :personas_not_thumbnailed))
    drop(index(:episodes, [:id], name: :episodes_not_thumbnailed))

    create(
      index(:podcasts, [:id],
        where: "thumbnailed IS FALSE AND NOT image_url IS NULL",
        name: :podcasts_not_thumbnailed_v2
      )
    )

    create(
      index(:personas, [:id],
        where: "thumbnailed IS FALSE AND NOT image_url IS NULL",
        name: :personas_not_thumbnailed_v2
      )
    )

    create(
      index(:episodes, [:id],
        where: "thumbnailed IS FALSE AND NOT image_url IS NULL",
        name: :episodes_not_thumbnailed_v2
      )
    )
  end
end
