defmodule Pan.Repo.Migrations.DropProPlanFieldsFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:pro_until, :naive_datetime)
      remove(:payment_reference, :string)
      remove(:billing_address, :text)
      remove(:paper_bill, :boolean)
    end
  end
end
