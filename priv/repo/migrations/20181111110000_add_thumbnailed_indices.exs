defmodule Pan.Repo.Migrations.AddThumbnailedIndices do
  use Ecto.Migration

  def change do
    create(
      index(:podcasts, [:id],
        where: "thumbnailed IS NULL AND NOT image_url IS NULL",
        name: :podcasts_not_thumbnailed
      )
    )

    create(
      index(:personas, [:id],
        where: "thumbnailed IS NULL AND NOT image_url IS NULL",
        name: :personas_not_thumbnailed
      )
    )

    create(
      index(:episodes, [:id],
        where: "thumbnailed IS NULL AND NOT image_url IS NULL",
        name: :episodes_not_thumbnailed
      )
    )
  end
end
