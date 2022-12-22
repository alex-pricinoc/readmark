defmodule Readmark.Repo.Migrations.CreateBookmarks do
  use Ecto.Migration

  def change do
    create table(:bookmarks) do
      add :url, :text, null: false
      add :title, :text, null: false
      add :tags, {:array, :string}

      add :notes, :text
      add :is_private, :boolean, default: true

      timestamps()
    end
  end
end
