defmodule Pan.Repo.Migrations.UniqueConstraintsForRelations do
  use Ecto.Migration

  def change do
    create(unique_index(:categories_podcasts, [:category_id, :podcast_id]))
    create(unique_index(:subscriptions, [:user_id, :podcast_id]))
    create(unique_index(:follows, [:follower_id, :podcast_id, :user_id, :category_id]))

    create(
      unique_index(:likes, [
        :enjoyer_id,
        :podcast_id,
        :user_id,
        :category_id,
        :episode_id,
        :chapter_id
      ])
    )

    create(unique_index(:contributors_podcasts, [:contributor_id, :podcast_id]))
    create(unique_index(:languages_podcasts, [:language_id, :podcast_id]))
    create(unique_index(:contributors_episodes, [:contributor_id, :episode_id]))
  end
end
