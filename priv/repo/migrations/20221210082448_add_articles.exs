defmodule Readmark.Repo.Migrations.AddArticles do
  use Ecto.Migration

  def change do
    create table(:articles, primary_key: false) do
      add :url, :string, primary_key: true
      add :title, :text
      add :article_html, :text
      add :article_text, :text
      add :authors, {:array, :string}

      timestamps()
    end

    create index(:articles, [:url])

    create table(:bookmark_articles) do
      add :bookmark_id,
          references(:bookmarks, column: :id, type: :uuid, on_delete: :delete_all),
          null: false

      add :article_id,
          references(:articles, column: :url, type: :string, on_delete: :delete_all),
          null: false

      timestamps()
    end

    create unique_index(:bookmark_articles, [:bookmark_id, :article_id])
  end
end
