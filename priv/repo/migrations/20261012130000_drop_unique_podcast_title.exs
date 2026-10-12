defmodule Pan.Repo.Migrations.DropUniquePodcastTitle do
  use Ecto.Migration

  # Different podcasts carry the same title ("Deportes", "Embedded", ...).
  # The unique index made their monthly metadata refresh fail, and the first
  # import used the title as the podcast's identity, merging a different
  # show with the same title into an existing podcast. The first import now
  # identifies a podcast by its feed URL (Pan.Parser.Podcast.get_or_insert/3).
  # The plain title index for sorting (podcasts_title_ASC_NULLS_LAST_index)
  # stays.
  def up do
    drop(unique_index(:podcasts, [:title]))
  end

  # Fails once two podcasts share a title.
  def down do
    create(unique_index(:podcasts, [:title]))
  end
end
