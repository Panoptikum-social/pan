defmodule Pan.Repo.Migrations.AddPaymentFieldsTuUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :payment_reference, :string
      add :billing_address, :text
      add :paper_bill, :boolean
    end
  end
end
