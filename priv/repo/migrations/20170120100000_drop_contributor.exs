defmodule Pan.Repo.Migrations.DropContributor do
  use Ecto.Migration

  def change do
    drop(table(:contributors_episodes))
    drop(table(:contributors_podcasts))
    drop(table(:contributors))
  end
end
