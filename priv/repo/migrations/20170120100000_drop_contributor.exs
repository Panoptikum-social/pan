defmodule Pan.Repo.Migrations.CreateGig do
  use Ecto.Migration

  def change do
    drop(table(:contributors_episodes))
    drop(table(:contributors_podcasts))
    drop(table(:contributors))
  end
end
