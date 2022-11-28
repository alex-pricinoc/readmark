defmodule Readmark.Bookmarks do
  @moduledoc """
  The Bookmarks context.
  """

  import Ecto.Query, warn: false
  alias Readmark.Repo

  alias Readmark.Bookmarks.{Bookmark, Article}

  @doc """
  Returns the list of bookmarks.

  ## Examples

      iex> list_bookmarks()
      [%Bookmark{}, ...]

  """
  def list_bookmarks(params \\ []) do
    Bookmark
    |> order_by(desc: :inserted_at)
    |> where(^filter_where(params))
    |> Repo.all()
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:tags, tags}, dynamic when tags != [] ->
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
  Gets a single bookmark.

  Raises `Ecto.NoResultsError` if the Bookmark does not exist.

  ## Examples

      iex> get_bookmark!(123)
      %Bookmark{}

      iex> get_bookmark!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bookmark!(id, preload \\ []), do: Repo.get!(Bookmark, id) |> Repo.preload(preload)

  @doc """
  Creates a bookmark.

  ## Examples

      iex> create_bookmark(%{field: value})
      {:ok, %Bookmark{}}

      iex> create_bookmark(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bookmark(attrs \\ %{}) do
    %Bookmark{}
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
  Creates a bookmark article.

  ## Examples

      iex> create_bookmark_article(%{field: value})
      {:ok, %Bookmark{}}

      iex> create_bookmark_article(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bookmark_article(attrs \\ %{}) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single article by url.

  Returns nil if no article was found. Raises if more than one entry.

  ## Examples

      iex> get_article_by_url("https://example.com")
      %Article{}

      iex> get_article_by_url(456)
      nil

  """
  def get_article_by_url(url), do: Repo.get_by(Article, url: url)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bookmark changes.

  ## Examples

      iex> change_bookmark(bookmark)
      %Ecto.Changeset{data: %Bookmark{}}

  """
  def change_bookmark(%Bookmark{} = bookmark, attrs \\ %{}) do
    Bookmark.changeset(bookmark, attrs)
  end

  @topic "bookmarks"
  @pubsub Readmark.PubSub

  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  defp broadcast!({:error, _reason} = error, _event), do: error

  defp broadcast!({:ok, bookmark}, event) do
    Phoenix.PubSub.broadcast!(@pubsub, @topic, {event, bookmark})
    {:ok, bookmark}
  end
end
