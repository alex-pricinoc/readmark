defmodule Readmark.Bookmarks.Article do
  use Readmark.Schema

  alias Readmark.Bookmarks.{Bookmark, BookmarkArticle}

  @type t :: Ecto.Schema.t()

  @primary_key false
  schema "articles" do
    field :url, :string, primary_key: true
    field :title, :string
    field :article_html, :string
    field :article_text, :string
    field :authors, {:array, :string}

    many_to_many :bookmarks, Bookmark,
      join_through: BookmarkArticle,
      join_keys: [article_id: :url, bookmark_id: :id]

    timestamps()
  end

  @params ~w(url article_html article_text authors title inserted_at)a
  @required ~w(url article_text title)a

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, @params)
    |> validate_length(:url, max: 2048)
    |> validate_length(:title, max: 255)
    |> validate_required(@required)
    |> unique_constraint(:url, name: "articles_pkey")
  end
end
