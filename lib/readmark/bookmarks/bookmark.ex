defmodule Readmark.Bookmarks.Bookmark do
  use Readmark.Schema
  import Ecto.Changeset

  alias Readmark.Bookmarks.Tag

  @params ~w(url title tags inserted_at is_private notes content user_id)a
  @required ~w(url title user_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "bookmarks" do
    field :url, :string
    field :title, :string
    field :tags, Tag, default: []
    field :notes, :string, default: ""
    field :is_private, :boolean, default: true
    field :content, :string

    belongs_to :user, User

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
end
