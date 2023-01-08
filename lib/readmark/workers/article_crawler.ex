defmodule Readmark.Workers.ArticleCrawler do
  use Oban.Worker, max_attempts: 1

  require Logger

  alias Readmark.Repo
  alias Readmark.{Bookmarks, Readability}
  alias Bookmarks.{Bookmark, Article}

  @impl Oban.Worker
  def perform(%{args: %{"bookmark_id" => bookmark_id}}) do
    bookmark = Repo.get!(Bookmark, bookmark_id) |> Repo.preload(:articles)

    with %Article{} = article <- get_or_fetch_article(bookmark.url),
         {:ok, _} <- Bookmarks.update_bookmark(bookmark, %{"articles" => [article]}) do
      :ok
    else
      {:error, error} ->
        Logger.error("Unable to save bookmark #{inspect(error)}")
        {:error, error}

      error ->
        Logger.error("Unable to save bookmark #{inspect(error)}")
        {:error, error}
    end
  end

  @doc "Fetches the article for a given bookmark and updates it."
  def fetch_article(%Bookmark{id: id}) do
    %{bookmark_id: id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Retrieves an existing article from the db or fetches and inserts a new one.

  Returns an `Article` struct or `nil`.
  """
  def get_or_fetch_article(url) do
    Repo.get(Article, url) || maybe_insert_article(Readability.summarize(url))
  end

  defp maybe_insert_article({:ok, %Readability.Summary{} = summary}) do
    %Article{}
    |> Article.changeset(attrs_from_summary(summary))
    |> Repo.insert()
    |> case do
      {:ok, article} ->
        article

      {:error, error} ->
        Logger.error("Unable to insert article: #{inspect(error)}")
        Repo.get(Article, summary.url)
    end
  end

  defp maybe_insert_article({:error, error}) do
    Logger.error("Unable to summarize article: #{inspect(error)}")
    nil
  end

  defp attrs_from_summary(summary) do
    %{
      url: summary.url,
      article_html: summary.content,
      article_text: summary.text_content,
      title: summary.title
    }
  end
end
