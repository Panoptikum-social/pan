defmodule Pan.Repo.Migrations.CreateInvoice do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add(:filename, :string)
      add(:content_type, :string)
      add(:path, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:invoices, [:user_id]))
  end
end
