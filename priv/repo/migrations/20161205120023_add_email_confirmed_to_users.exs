defmodule Pan.Repo.Migrations.AddEmailConfirmedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:email_confirmed, :boolean)
    end
  end
end
