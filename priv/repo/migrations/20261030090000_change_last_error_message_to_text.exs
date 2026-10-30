defmodule Pan.Repo.Migrations.ChangeLastErrorMessageToText do
  use Ecto.Migration

  # Error texts are kept in full (e.g. a TLS bad_certificate alert with the
  # host names it was issued for), varchar(255) crashed the updater on them.
  def change do
    alter table(:podcasts) do
      modify(:last_error_message, :text, from: :string)
    end
  end
end
