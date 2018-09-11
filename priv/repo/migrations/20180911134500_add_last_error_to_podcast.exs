defmodule Pan.Repo.Migrations.AddLastErrorToPodcast do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :last_error_message, :string
      add :last_error_occured, :naive_datetime
    end
  end
end
