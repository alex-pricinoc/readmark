defmodule Readmark.Workers.ArticleFetcher do
  use GenServer

  require Logger

  alias Readmark.Repo
  alias Readmark.{Bookmarks, Readability}
  alias Bookmarks.{Article, Bookmark}

  @name __MODULE__

  # Client

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: @name)

  @doc """
  Fetches the article of a bookmark.
  """
  def fetch_bookmark(%Bookmark{} = bookmark), do: GenServer.cast(@name, {:fetch, bookmark})

  @doc """
  Retrieves an existing article from the db or fetches and inserts a new one.

  Returns an `Article` struct or `nil`.
  """
  def get_or_fetch_article(url) when is_binary(url), do: GenServer.call(@name, {:fetch, url})

  # Server (callbacks)

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:fetch, bookmark}, state) do
    bookmark = Repo.preload(bookmark, :articles)

    with %Article{} = article <- get_or_fetch_article(bookmark.url),
         {:ok, _bookmark} <- Bookmarks.update_bookmark(bookmark, %{"articles" => [article]}) do
      :ok
    else
      error ->
        Logger.error("Unable to save bookmark #{inspect(error)}")
        {:error, error}
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:fetch, url}, _from, state) do
    article = Repo.get(Article, url) || maybe_insert_article(url, Readability.summarize(url))

    {:reply, article, state}
  end

  defp maybe_insert_article(url, {:ok, attrs}) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, article} ->
        article

      {:error, error} ->
        Logger.error("Unable to insert article: #{inspect(error)}")
        Repo.get(Article, url)
    end
  end

  defp maybe_insert_article(_url, {:error, error}) do
    Logger.error("Unable to summarize article: #{inspect(error)}")
    nil
  end
end
