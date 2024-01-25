defmodule Readmark.Workers.ArticleFetcher do
  require Logger

  alias Readmark.{Repo, Bookmarks}
  alias Bookmarks.Article

  @readability Application.compile_env!(:readmark, :readability)

  @doc """
  Retrieves an existing article from the db or fetches and inserts a new one.

  Returns an `Article` struct or `nil`.
  """
  def fetch_article(url) when is_binary(url) do
    Repo.get(Article, url) || maybe_insert_article(url, @readability.summarize(url))
  end

  defp maybe_insert_article(url, {:ok, attrs}) do
    attrs
    |> Bookmarks.create_article()
    |> case do
      {:ok, article} ->
        article

      {:error, error} ->
        Logger.debug("Unable to insert article: #{inspect(error)}")
        Repo.get(Article, url)
    end
  end

  defp maybe_insert_article(_url, {:error, error}) do
    Logger.warning("Unable to summarize article: #{inspect(error)}")
    nil
  end
end
