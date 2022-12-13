defmodule Readmark.Bookmarks.BookmarkArticle do
  use Readmark.Schema

  alias Readmark.Bookmarks.{Bookmark, Article}

  schema "bookmark_articles" do
    belongs_to :bookmark, Bookmark, references: :id, type: :binary_id
    belongs_to :article, Article, references: :url, type: :string

    timestamps()
  end
end
