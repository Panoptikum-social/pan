defmodule Pan.Repo.Migrations.CreateContributersPodcasts do
  use Ecto.Migration

  def change do
    create table(:contributers_podcasts, primary_key: false) do
      add :contributer_id, references(:contributers)
      add :podcast_id, references(:podcasts)
    end
  end
end
