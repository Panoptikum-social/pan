defmodule Pan.Repo.Migrations.AddNoHeadersIndicator do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add(:hash, :string)
    end
  end
end
