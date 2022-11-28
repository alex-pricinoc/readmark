defmodule Readmark.Repo.Migrations.AddArticleContentToBookmarks do
  use Ecto.Migration

  def change do
    alter table(:bookmarks) do
      add :content, :text
    end
  end
end
