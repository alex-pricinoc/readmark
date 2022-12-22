defmodule Readmark.Repo.Migrations.AddArticles do
  use Ecto.Migration

  def change do
    create table(:articles, primary_key: false) do
      add :url, :string, primary_key: true
      add :title, :text, null: false
      add :article_html, :text
      add :article_text, :text, null: false
      add :authors, {:array, :string}

      timestamps()
    end

    create table(:bookmark_articles, primary_key: false) do
      add :bookmark_id,
          references(:bookmarks, column: :id, type: :id, on_delete: :delete_all),
          null: false,
          primary_key: true

      add :article_id,
          references(:articles, column: :url, type: :string, on_delete: :delete_all),
          null: false,
          primary_key: true

      timestamps()
    end
  end
end
