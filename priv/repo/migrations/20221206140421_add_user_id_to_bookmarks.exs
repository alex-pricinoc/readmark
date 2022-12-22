defmodule Readmark.Repo.Migrations.AddUserIdToBookmarks do
  use Ecto.Migration

  def change do
    alter table(:bookmarks) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create index(:bookmarks, [:user_id])
  end
end
