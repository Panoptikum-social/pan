defmodule Pan.Repo.Migrations.AddProUntilToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:pro_until, :naive_datetime)
    end
  end
end
