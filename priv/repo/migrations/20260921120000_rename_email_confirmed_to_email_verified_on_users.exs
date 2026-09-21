defmodule Pan.Repo.Migrations.RenameEmailConfirmedToEmailVerifiedOnUsers do
  use Ecto.Migration

  def change do
    rename(table(:users), :email_confirmed, to: :email_verified)
  end
end
