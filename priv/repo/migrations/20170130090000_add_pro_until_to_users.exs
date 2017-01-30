defmodule Pan.Repo.Migrations.AddProUntilToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pro_until, :datetime
    end
  end
end
