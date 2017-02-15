defmodule Pan.Repo.Migrations.NewFullTextSearchIndices do
  use Ecto.Migration

  def up do
    execute "CREATE extension if not exists pg_trgm;"

    execute "CREATE INDEX podcasts_search_idx ON podcasts USING " <>
            "gin(title gin_trgm_ops, summary gin_trgm_ops, description gin_trgm_ops);"
    execute "CREATE INDEX episodes_search_idx ON episodes USING " <>
            "gin(title gin_trgm_ops, summary gin_trgm_ops, description gin_trgm_ops, " <>
                "shownotes gin_trgm_ops, subtitle gin_trgm_ops);"
  end

  def down do
    execute "DROP INDEX podcasts_search_idx;"
    execute "DROP INDEX episodes_search_idx;"
  end
end