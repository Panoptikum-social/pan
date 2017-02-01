defmodule Pan.Repo.Migrations.RemoveFullTextSearchIndices do
  use Ecto.Migration

  def up do
    execute "DROP INDEX podcasts_fulltext_idx;"
    execute "DROP INDEX episodes_fulltext_idx;"
  end

  def down do
    execute "CREATE extension if not exists pg_trgm;"

    execute "CREATE INDEX podcasts_fulltext_idx ON podcasts USING gin(to_tsvector('german', title || ' ' || summary || ' ' || description || ' ' || author));"
    execute "CREATE INDEX episodes_fulltext_idx ON episodes USING gin(to_tsvector('german', title || ' ' || summary || ' ' || description || ' ' || author || ' ' || shownotes || ' ' || subtitle));"
  end
end