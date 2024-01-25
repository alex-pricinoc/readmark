defmodule Readmark.Repo.Migrations.UpdateArticles do
  use Ecto.Migration

  def up do
    alter table(:articles) do
      modify :url, :text
    end

    alter table(:bookmark_articles) do
      modify :article_id, :text
    end
  end

  def down do
    alter table(:articles) do
      modify :url, :string
    end

    alter table(:bookmark_articles) do
      modify :article_id, :string
    end
  end
end
