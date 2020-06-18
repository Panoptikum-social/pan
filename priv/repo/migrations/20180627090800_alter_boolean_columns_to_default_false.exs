defmodule Pan.Repo.Migrations.AlterColumnsToDefaultFalse do
  use Ecto.Migration

  def up do
    alter table("podcasts") do
      modify(:blocked, :boolean, default: false)
      modify(:update_paused, :boolean, default: false)
    end

    alter(table("podcasts"), do: modify(:elastic, :boolean, default: false))
    alter(table("categories"), do: modify(:elastic, :boolean, default: false))
    alter(table("episodes"), do: modify(:elastic, :boolean, default: false))
    alter(table("personas"), do: modify(:elastic, :boolean, default: false))
    alter(table("gigs"), do: modify(:self_proclaimed, :boolean, default: false))

    alter table("users") do
      modify(:admin, :boolean, default: false)
      modify(:podcaster, :boolean, default: false)
      modify(:email_confirmed, :boolean, default: false)
      modify(:share_subscriptions, :boolean, default: false)
      modify(:share_follows, :boolean, default: false)
      modify(:paper_bill, :boolean, default: false)
      modify(:elastic, :boolean, default: false)
    end
  end

  def down do
    alter table("podcasts") do
      modify(:blocked, :boolean, default: nil)
      modify(:update_paused, :boolean, default: nil)
    end

    alter(table("podcasts"), do: modify(:elastic, :boolean, default: nil))
    alter(table("categories"), do: modify(:elastic, :boolean, default: nil))
    alter(table("episodes"), do: modify(:elastic, :boolean, default: nil))
    alter(table("personas"), do: modify(:elastic, :boolean, default: nil))
    alter(table("gigs"), do: modify(:self_proclaimed, :boolean, default: nil))

    alter table("users") do
      modify(:admin, :boolean, default: nil)
      modify(:podcaster, :boolean, default: nil)
      modify(:email_confirmed, :boolean, default: nil)
      modify(:share_subscriptions, :boolean, default: nil)
      modify(:share_follows, :boolean, default: nil)
      modify(:paper_bill, :boolean, default: nil)
      modify(:elastic, :boolean, default: nil)
    end
  end
end
