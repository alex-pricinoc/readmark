defmodule Readmark.ArticleFetcher.Impl do
  require Logger

  alias Readmark.Repo
  alias Readmark.{Bookmarks, Readability}
  alias Bookmarks.Article

  def fetch_bookmark_article(bookmark) do
    bookmark = Repo.preload(bookmark, :articles)

    with %Article{} = article <- get_or_fetch_article(bookmark.url),
         {:ok, _bookmark} <- Bookmarks.update_bookmark(bookmark, %{"articles" => [article]}) do
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

  def get_or_fetch_article(url) do
    Repo.get(Article, url) || maybe_insert_article(summarize(url))
  end

  defp summarize(url) do
    Task.await(Task.async(fn -> Readability.summarize(url) end))
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
