defmodule Pan.Repo.Migrations.AddNoHeadersIndicator do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add(:no_headers_available, :boolean, default: false)
    end
  end
end
