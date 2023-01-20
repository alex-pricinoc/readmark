defmodule Readmark.Bookmarks do
  @moduledoc """
  The Bookmarks context.
  """

  import Ecto.Query, warn: false
  alias Readmark.Repo

  alias Readmark.Accounts.User
  alias Readmark.Bookmarks.{Bookmark, BookmarkArticle}

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
    Bookmark
    |> order_by(desc: :inserted_at)
    |> where(^filter_where(params))
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
    |> order_by(desc: :inserted_at)
    |> where(^filter_where(folder: :reading, user_id: user.id))
    |> limit(10)
    |> Repo.all()
  end

  defp reading_articles_query do
    from b in Bookmark,
      as: :bookmark,
      where: exists(from ba in BookmarkArticle, where: parent_as(:bookmark).id == ba.bookmark_id),
      preload: :articles
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
    |> broadcast!({:bookmark, :created})
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
    |> broadcast!({:bookmark, :updated})
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
    |> broadcast!({:bookmark, :deleted})
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

  @pubsub Readmark.PubSub

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user_id))
  end

  defp topic(user_id), do: "bookmarks:#{user_id}"

  def broadcast!({:error, _reason} = error, _event), do: error

  def broadcast!({:ok, bookmark} = result, event) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(bookmark.user_id), {event, bookmark})
    result
  end
end
