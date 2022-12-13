defmodule Readmark.Repo.Migrations.AddUserIdToBookmarks do
  use Ecto.Migration

  def change do
    alter table(:bookmarks) do
      remove :id
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :nothing), primary_key: true
    end

    create unique_index(:bookmarks, [:id])
    create index(:bookmarks, [:user_id])
    create index(:bookmarks, [:id, :user_id])
  end
end
