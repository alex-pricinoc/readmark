defmodule Readmark.Bookmarks.Bookmark do
  use Readmark.Schema

  alias Readmark.Bookmarks.{Tag, BookmarkArticle, Article}

  @params ~w(url title tags inserted_at is_private notes user_id folder)a
  @required ~w(url title user_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "bookmarks" do
    field :url, :string
    field :title, :string
    field :tags, Tag, default: []
    field :notes, :string, default: ""
    field :is_private, :boolean, default: true
    field :folder, Ecto.Enum, values: [:reading, :bookmarks, :archive], default: :bookmarks

    belongs_to :user, User

    many_to_many :articles, Article,
      join_through: BookmarkArticle,
      join_keys: [bookmark_id: :id, article_id: :url]

    timestamps()
  end

  @doc false
  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, @params)
    |> validate_required(@required)
    |> validate_length(:url, max: 2048)
    |> validate_length(:title, max: 255)
    |> assoc_constraint(:user)
  end

  @doc false
  def article_changeset(bookmark, article) do
    bookmark
    |> change
    |> put_assoc(:articles, [article | bookmark.articles])
  end
end
