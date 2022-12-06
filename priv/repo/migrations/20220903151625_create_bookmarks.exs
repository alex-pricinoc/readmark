defmodule Readmark.Repo.Migrations.CreateBookmarks do
  use Ecto.Migration

  def change do
    create table(:bookmarks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :url, :text
      add :title, :text
      add :tags, {:array, :string}

      add :notes, :text
      add :is_private, :boolean, default: false

      timestamps()
    end

    create index(:bookmarks, [:id])
  end
end
