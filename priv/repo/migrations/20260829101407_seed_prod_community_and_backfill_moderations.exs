defmodule Pan.Repo.Migrations.SeedProdCommunityAndBackfillModerations do
  use Ecto.Migration

  # Seeds the Community row for every community-category that exists in
  # practice today per backlog.md: 106 ("Wissenschaftspodcasts.de", the only
  # one with moderators so far) plus its 3 currently-unmoderated siblings
  # under category 105 ("👩 👨 Community") — 113 ("Kulturkapital -
  # Museumspodcasts"), 115 ("Podcasterei.at"), 142 ("Frauenstimmen").
  # Backfills existing moderation rows (currently only the 3 under 106) onto
  # their new community_id. Runs in dev/test/prod; no-ops on QA
  # (`config :pan, :environment == "qa"`, see config/qa.exs) since QA doesn't
  # carry this real-world data. Also no-ops per-category wherever that
  # category itself doesn't exist (e.g. a fresh/synthetic test DB), so it
  # can't fail on the category_id FK there.
  @communities [
    {106, "Wissenschaftspodcasts.de"},
    {113, "Kulturkapital - Museumspodcasts"},
    {115, "Podcasterei.at"},
    {142, "Frauenstimmen"}
  ]

  def up do
    unless qa?() do
      for {category_id, title} <- @communities do
        execute("""
        INSERT INTO communities (title, category_id, inserted_at, updated_at)
        SELECT '#{escape(title)}', id, NOW(), NOW()
        FROM categories
        WHERE id = #{category_id}
        ON CONFLICT (category_id) DO NOTHING
        """)

        execute("""
        UPDATE moderations
        SET community_id = (SELECT id FROM communities WHERE category_id = #{category_id})
        WHERE category_id = #{category_id}
        """)
      end
    end
  end

  def down do
    unless qa?() do
      for {category_id, _title} <- @communities do
        execute("UPDATE moderations SET community_id = NULL WHERE category_id = #{category_id}")
        execute("DELETE FROM communities WHERE category_id = #{category_id}")
      end
    end
  end

  defp qa?, do: Application.get_env(:pan, :environment) == "qa"

  defp escape(string), do: String.replace(string, "'", "''")
end
