defmodule Readmark.Repo.Migrations.AddTagsIndexToBookmarks do
  use Ecto.Migration

  def change do
    create index(:bookmarks, [:tags], using: "GIN")
  end
end
