defmodule Readmark.Workers.ArticleFetcher do
  use GenServer

  require Logger

  alias Readmark.{Repo, Bookmarks}
  alias Bookmarks.{Article, Bookmark}

  @readability Application.compile_env!(:readmark, :readability)

  @name __MODULE__

  # Client

  @doc false
  def start_link([] = _opts), do: GenServer.start_link(__MODULE__, :no_state, name: @name)

  @doc """
  Fetches the article of a bookmark.
  """
  def fetch_bookmark(%Bookmark{} = bookmark), do: GenServer.cast(@name, {:fetch, bookmark})

  @doc """
  Retrieves an existing article from the db or fetches and inserts a new one.

  Returns an `Article` struct or `nil`.
  """
  def get_article(url) when is_binary(url), do: GenServer.call(@name, {:fetch, url})

  # Server (callbacks)

  @impl true
  def init(:no_state) do
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
        Logger.error("Unable to update bookmark with article: #{inspect(error)}")
        {:error, error}
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:fetch, url}, _from, state) do
    {:reply, get_or_fetch_article(url), state}
  end

  defp get_or_fetch_article(url) do
    Repo.get(Article, url) || maybe_insert_article(url, @readability.summarize(url))
  end

  defp maybe_insert_article(url, {:ok, attrs}) do
    attrs
    |> Bookmarks.create_article()
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
