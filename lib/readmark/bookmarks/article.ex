defmodule Readmark.Bookmarks.Article do
  use Readmark.Schema
  import Ecto.Changeset

  @params ~w(url article_html article_text authors title)a
  @required ~w(url)a

  schema "bookmark_articles" do
    field :url, :string
    field :authors, {:array, :string}
    field :article_html, :string
    field :article_text, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, @params)
    |> validate_required(@required)
  end
end
