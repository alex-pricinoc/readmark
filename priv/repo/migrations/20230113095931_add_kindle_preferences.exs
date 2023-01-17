defmodule Readmark.Repo.Migrations.AddKindlePreferences do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :kindle_preferences, :map
    end
  end
end
