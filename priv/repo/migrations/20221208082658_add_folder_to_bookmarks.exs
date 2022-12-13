defmodule Readmark.Repo.Migrations.AddFolderToBookmarks do
  use Ecto.Migration

  def change do
    alter table(:bookmarks) do
      add :folder, :string, null: false, default: "bookmarks"
    end

    create index(:bookmarks, [:folder])
  end
end
