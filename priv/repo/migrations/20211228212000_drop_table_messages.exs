defmodule Pan.Repo.Migrations.DropTableMessages do
  use Ecto.Migration

  def change do
    drop table(:messages)
  end
end
