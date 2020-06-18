defmodule Pan.Repo.Migrations.AddEmojiToLanguages do
  use Ecto.Migration

  def change do
    rename(table(:languages), :name, to: :emoji)

    alter table(:languages) do
      add(:name, :string)
    end
  end
end
