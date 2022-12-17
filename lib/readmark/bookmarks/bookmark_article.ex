defmodule Readmark.Bookmarks.BookmarkArticle do
  use Readmark.Schema

  alias Readmark.Bookmarks.{Bookmark, Article}

  @primary_key false
  schema "bookmark_articles" do
    belongs_to :bookmark, Bookmark, references: :id, type: :binary_id, primary_key: true
    belongs_to :article, Article, references: :url, type: :string, primary_key: true

    timestamps()
  end
end
