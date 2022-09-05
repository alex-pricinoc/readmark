defmodule Readmark.Repo.Migrations.CreateBookmarks do
  use Ecto.Migration

  def change do
    create table(:bookmarks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :url, :string
      add :title, :string
      add :tags, {:array, :string}

      timestamps()
    end

    create index(:bookmarks, [:url])
  end
end
