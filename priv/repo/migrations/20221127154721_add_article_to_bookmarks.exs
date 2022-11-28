defmodule Readmark.Repo.Migrations.AddArticleToBookmarks do
  use Ecto.Migration

  def change do
    alter table(:bookmarks) do
      add :article_id, references(:bookmark_articles)
    end

    create index(:bookmarks, [:article_id])
  end
end
