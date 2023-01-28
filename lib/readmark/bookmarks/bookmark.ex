defmodule Readmark.Bookmarks.Bookmark do
  use Readmark.Schema

  alias Readmark.Accounts.User
  alias Readmark.Bookmarks.{Tag, BookmarkArticle, Article}

  @type t :: Ecto.Schema.t()

  schema "bookmarks" do
    field :url, :string
    field :title, :string
    field :tags, Tag, default: []
    field :notes, :string, default: ""
    field :is_private, :boolean, default: true
    field :folder, Ecto.Enum, values: [:reading, :bookmarks, :archive], default: :bookmarks

    belongs_to :user, User, foreign_key: :user_id

    many_to_many :articles, Article,
      join_through: BookmarkArticle,
      join_keys: [bookmark_id: :id, article_id: :url],
      on_replace: :delete

    timestamps()
  end

  @params ~w(url title tags inserted_at is_private user_id folder)a
  @required ~w(url title user_id)a

  @doc false
  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, @params)
    |> validate_required(@required)
    |> validate_length(:url, max: 2048)
    |> validate_url(:url)
    |> validate_length(:title, max: 255)
    |> assoc_constraint(:user)
    |> maybe_insert_articles(attrs)
  end

  defp maybe_insert_articles(changeset, %{"articles" => articles}) do
    put_assoc(changeset, :articles, articles)
  end

  defp maybe_insert_articles(changeset, _attrs) do
    changeset
  end

  defp validate_url(changeset, field, opts \\ []) do
    validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: nil} ->
          "is missing a scheme (e.g. https)"

        %URI{host: nil} ->
          "is missing a host"

        %URI{host: host} ->
          case :inet.gethostbyname(Kernel.to_charlist(host)) do
            {:ok, _} -> nil
            {:error, _} -> "invalid host"
          end
      end
      |> case do
        error when is_binary(error) -> [{field, Keyword.get(opts, :message, error)}]
        _ -> []
      end
    end)
  end
end
