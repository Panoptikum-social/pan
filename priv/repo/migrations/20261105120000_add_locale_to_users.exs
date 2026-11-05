defmodule Pan.Repo.Migrations.AddLocaleToUsers do
  use Ecto.Migration

  # The user's interface language (Project #4, #563), set by the EN/DE
  # switcher in the sidebar. NULL means not chosen yet: cookie and browser
  # language decide.
  def change do
    alter table(:users) do
      add(:locale, :string)
    end
  end
end
