defmodule Pan.Repo.Migrations.BackfillLastLoginAtForVerifiedUsers do
  use Ecto.Migration

  # There is no real login history before last_login_at existed, so updated_at is
  # the best available approximation for accounts with a verified address.
  # Unverified accounts are deliberately left empty, they are handled individually.
  def up do
    execute("""
    UPDATE users
    SET last_login_at = updated_at
    WHERE email_verified = true AND last_login_at IS NULL
    """)
  end

  def down, do: :ok
end
