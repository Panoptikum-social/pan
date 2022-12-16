defmodule Pan.Repo.Migrations.AlteMoreColumnsToDefaultFalseAgain do
  use Ecto.Migration

  def change do
    alter(table("podcasts"), do: modify(:explicit, :boolean, default: false))
    alter(table("podcasts"), do: modify(:retired, :boolean, default: false))
    alter(table("users"), do: modify(:moderator, :boolean, default: false))
    alter(table("backlog_feeds"), do: modify(:in_progress, :boolean, default: false))
    alter(table("gigs"), do: modify(:self_proclaimed, :boolean, default: false))
  end
end
