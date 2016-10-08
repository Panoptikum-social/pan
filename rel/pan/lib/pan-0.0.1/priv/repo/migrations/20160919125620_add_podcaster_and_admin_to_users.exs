defmodule Pan.Repo.Migrations.AddPodcasterAndAdminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :admin, :boolean
      add :podcaster, :boolean
    end
  end
end
