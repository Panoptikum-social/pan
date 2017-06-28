defmodule Pan.Repo.Migrations.AddSelfProclaimedtoGigs do
  use Ecto.Migration

  def change do
    alter table(:gigs) do
      add :self_proclaimed, :boolean
    end
  end
end
