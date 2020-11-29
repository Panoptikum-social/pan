defmodule Pan.Repo.Migrations.AlteMoreColumnsToDefaultFalse do
  use Ecto.Migration

  def change do
    alter(table("podcasts"), do: modify(:thumbnailed, :boolean, default: false))
    alter(table("episodes"), do: modify(:thumbnailed, :boolean, default: false))
    alter(table("personas"), do: modify(:thumbnailed, :boolean, default: false))
  end
end
