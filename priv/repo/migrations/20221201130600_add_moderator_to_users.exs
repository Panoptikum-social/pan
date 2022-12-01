defmodule Pan.Repo.Migrations.AddPodcasterAndAdminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:moderator, :boolean)
    end
  end
end
