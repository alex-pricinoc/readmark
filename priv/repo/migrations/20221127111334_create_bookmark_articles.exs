defmodule Readmark.Repo.Migrations.CreateBookmarkArticles do
  use Ecto.Migration

  def change do
    create table(:bookmark_articles) do
      add :url, :text
      add :title, :text
      add :article_html, :text
      add :article_text, :text
      add :authors, {:array, :string}

      timestamps()
    end

    create index(:bookmark_articles, [:url])
  end
end
