defmodule Readmark.Repo.Migrations.AddUserIdToBookmarks do
  use Ecto.Migration

  def up do
    drop constraint(:bookmarks, "bookmarks_pkey")

    alter table(:bookmarks) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      modify :id, :uuid, primary_key: true
    end

    create unique_index(:bookmarks, [:id])
  end

  def down do
    alter table(:bookmarks) do
      remove :user_id
      modify :id, :uuid, primary_key: true
    end

    drop index(:bookmarks, [:id])
  end
end
