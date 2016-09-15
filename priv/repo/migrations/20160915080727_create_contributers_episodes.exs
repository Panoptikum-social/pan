defmodule Pan.Repo.Migrations.CreateContributersEpisodes do
  use Ecto.Migration

  def change do
    create table(:contributers_episodes, primary_key: false) do
      add :contributer_id, references(:contributers)
      add :episode_id, references(:episodes)
    end
  end
end
