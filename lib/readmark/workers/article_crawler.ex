defmodule Readmark.Workers.ArticleCrawler do
  use Oban.Worker, max_attempts: 1

  require Logger

  alias Readmark.Repo
  alias Readmark.Bookmarks
  alias Bookmarks.{Bookmark, Article}

  @impl Oban.Worker
  def perform(%{args: %{"bookmark_id" => bookmark_id}}) do
    bookmark = Repo.get!(Bookmark, bookmark_id) |> Repo.preload(:articles)

    with %Article{} = article <- get_or_fetch_article(bookmark.url),
         {:ok, bookmark} <- Bookmarks.update_bookmark(bookmark, %{"articles" => [article]}) do
      {:ok, bookmark}
    else
      {:error, error} ->
        Logger.error("Unable to save bookmark #{inspect(error)}")
        {:error, error}

      error ->
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
    Repo.get(Article, url) || maybe_insert_article(summarize(url))
  end

  defp maybe_insert_article(attrs) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, article} ->
        article

      {:error, error} ->
        Logger.error("Unable to insert article: #{inspect(error)}")
        Repo.get(Article, attrs.url)
    end
  end

  defp summarize(url) do
    summary =
      try do
        Readability.summarize(url)
      rescue
        e ->
          Logger.error(Exception.format(:error, e, __STACKTRACE__))
          %Readability.Summary{article_text: "Unable to save article"}
      end

    %Readability.Summary{
      title: title,
      authors: authors,
      article_html: html,
      article_text: text
    } = summary

    %{
      url: url,
      authors: authors,
      article_html: html,
      article_text: text,
      title: title
    }
  end
end
