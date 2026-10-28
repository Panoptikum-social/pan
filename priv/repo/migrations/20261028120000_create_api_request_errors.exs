defmodule Pan.Repo.Migrations.CreateApiRequestErrors do
  use Ecto.Migration

  # Failed API requests on podcasts, for the moderators' API error page, see
  # PanWeb.ApiRequestError. No foreign key on podcast_id: requests for
  # podcasts that no longer exist are recorded too.
  def change do
    create table(:api_request_errors) do
      add(:podcast_id, :integer)
      add(:endpoint, :string, null: false)
      add(:status, :integer, null: false)
      add(:title, :string)
      add(:detail, :string)

      timestamps(updated_at: false)
    end

    create(index(:api_request_errors, [:inserted_at]))
    create(index(:api_request_errors, [:podcast_id]))
  end
end
