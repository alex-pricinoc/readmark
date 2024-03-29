defmodule Readmark.Bookmarks do
  @moduledoc """
  The Bookmarks context.
  """

  import Ecto.Query, warn: false

  require Logger

  alias Readmark.Repo

  alias Readmark.Accounts.User
  alias Readmark.Bookmarks.{Bookmark, BookmarkArticle, Article}

  @doc """
  Returns all Bookmarks belonging to the given user.
  """
  def paginate_bookmarks(%User{} = user, params \\ [], opts \\ []) do
    params = Keyword.put(params, :user_id, user.id)

    params
    |> all_query()
    |> Repo.paginate(opts)
  end

  @doc false
  def all_query(params) when is_list(params) do
    from b in Bookmark,
      as: :bookmark,
      order_by: [desc: :inserted_at],
      where: ^filter_where(params)
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:user_id, id}, dynamic ->
        dynamic([b], ^dynamic and b.user_id == ^id)

      {:folder, folder}, dynamic ->
        dynamic([b], ^dynamic and b.folder == ^folder)

      {:tags, tags}, dynamic when not is_nil(tags) and tags != [] ->
        dynamic(
          [b],
          ^dynamic and
            fragment(
              "? @> string_to_array(?, ',')::varchar[]",
              b.tags,
              ^Enum.join(tags, ",")
            )
        )

      {_, _}, dynamic ->
        dynamic
    end)
  end

  @doc """
  Returns the latest 10 currently reading bookmarks of a user.
  """
  def latest_unread_bookmarks(%User{} = user) do
    reading_articles_query()
    |> order_by(asc: :inserted_at)
    |> where(^filter_where(folder: :reading, user_id: user.id))
    |> limit(10)
    |> Repo.all()
  end

  defp archived_bookmark_query do
    from ba in BookmarkArticle, where: parent_as(:bookmark).id == ba.bookmark_id
  end

  defp reading_articles_query do
    from b in Bookmark,
      as: :bookmark,
      where: exists(archived_bookmark_query()),
      preload: :articles
  end

  def prune_archived_bookmarks() do
    Repo.transaction(fn ->
      from(b in Bookmark,
        where: b.folder == :archive,
        where: b.updated_at < from_now(-1, "month")
      )
      |> Repo.stream()
      |> Enum.reduce(0, fn bookmark, acc ->
        case Repo.delete(bookmark) do
          {:ok, _} ->
            acc + 1

          {:error, error} ->
            Logger.error("Failed to prune bookmark: #{inspect(error)}")
            acc
        end
      end)
    end)
  end

  def prune_archived_articles() do
    Repo.transaction(fn ->
      from(a in Article,
        as: :article,
        where: a.inserted_at < from_now(-3, "month"),
        where:
          not exists(from(ba in BookmarkArticle, where: parent_as(:article).url == ba.article_id))
      )
      |> Repo.stream()
      |> Enum.reduce(0, fn article, acc ->
        case Repo.delete(article) do
          {:ok, _} ->
            acc + 1

          {:error, error} ->
            Logger.error("Failed to prune article: #{inspect(error)}")
            acc
        end
      end)
    end)
  end

  @doc """
  Gets a single bookmark by id and user_id.

  Raises `Ecto.NoResultsError` if the Bookmark does not exist.

  ## Examples

      iex> get_bookmark!(123, 456)
      %Bookmark{}

      iex> get_bookmark!(456, 789)
      ** (Ecto.NoResultsError)

  """
  def get_bookmark!(id, user_id),
    do: Repo.get_by!(Bookmark, id: id, user_id: user_id) |> Repo.preload(:articles)

  @doc """
  Creates a bookmark.

  ## Examples

      iex> create_bookmark(%User{}, %{field: value})
      {:ok, %Bookmark{}}

      iex> create_bookmark(%User{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bookmark(%User{} = user, attrs \\ %{}) do
    %Bookmark{user_id: user.id}
    |> Bookmark.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bookmark.

  ## Examples

      iex> update_bookmark(bookmark, %{field: new_value})
      {:ok, %Bookmark{}}

      iex> update_bookmark(bookmark, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bookmark(%Bookmark{} = bookmark, attrs) do
    bookmark
    |> Bookmark.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bookmark.

  ## Examples

      iex> delete_bookmark(bookmark)
      {:ok, %Bookmark{}}

      iex> delete_bookmark(bookmark)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bookmark(%Bookmark{} = bookmark) do
    bookmark
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bookmark changes.

  ## Examples

      iex> change_bookmark(bookmark)
      %Ecto.Changeset{data: %Bookmark{}}

  """
  def change_bookmark(%Bookmark{} = bookmark, attrs \\ %{}) do
    Bookmark.changeset(bookmark, attrs)
  end

  @doc """
  Creates an article.

  ## Examples

      iex> create_article(%{field: value})
      {:ok, %Article{}}

      iex> create_article(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_article(attrs \\ %{}) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
  end
end
