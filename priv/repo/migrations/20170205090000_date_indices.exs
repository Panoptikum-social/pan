defmodule Pan.Repo.Migrations.DateIndices do
  use Ecto.Migration

  def change do
    create index(:episodes,        ["publishing_date DESC NULLS LAST"])
    create index(:podcasts,        ["inserted_at DESC NULLS LAST"])
    create index(:recommendations, ["inserted_at DESC NULLS LAST"])
    create index(:gigs,            ["publishing_date DESC NULLS LAST"])
    create index(:messages,        ["inserted_at DESC NULLS LAST"])
    create index(:likes,           ["inserted_at DESC NULLS LAST"])

    create index(:podcasts,        ["title ASC NULLS LAST"])
    create index(:categories,      ["title ASC NULLS LAST"])
    create index(:chapters,        ["start ASC NULLS LAST"])
    create index(:personas,        ["name ASC NULLS LAST"])
    create index(:users,           ["name ASC NULLS LAST"])
  end
end