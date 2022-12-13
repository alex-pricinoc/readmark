defmodule Readmark.Workers.ArticleCrawler do
  use Oban.Worker, max_attempts: 1
  require Logger

  alias Readmark.Repo
  alias Readmark.Bookmarks
  alias Bookmarks.{Bookmark, Article}

  @impl Oban.Worker
  def perform(%{args: %{"bookmark_id" => bookmark_id}}) do
    bookmark = Repo.get!(Bookmark, bookmark_id) |> Repo.preload(:articles)

    if bookmark.folder == :reading and bookmark.articles == [] do
      if article = Repo.get(Article, bookmark.url) do
        save_bookmark_article(bookmark, article)
      else
        perform_fetch(bookmark)
      end
    else
      :ok
    end
  end

  def fetch_article(%Bookmark{id: id}) do
    %{bookmark_id: id}
    |> new()
    |> Oban.insert()
  end

  defp perform_fetch(bookmark) do
    summary =
      try do
        Readability.summarize(bookmark.url)
      rescue
        e ->
          Logger.error(Exception.format(:error, e, __STACKTRACE__))
          %Readability.Summary{article_text: "Unable to archive article"}
      end

    %Readability.Summary{
      title: title,
      authors: authors,
      article_html: html,
      article_text: text
    } = summary

    article = %Article{
      url: bookmark.url,
      authors: authors,
      article_html: html,
      article_text: text,
      title: title
    }

    case Repo.insert(article) do
      {:ok, article} ->
        save_bookmark_article(bookmark, article)

      {:error, error} ->
        Logger.error("Unable to save article #{inspect(error)}")
        {:error, error}
    end
  end

  defp save_bookmark_article(bookmark, article) do
    bookmark_article_changeset = Bookmark.article_changeset(bookmark, article)

    case Repo.update(bookmark_article_changeset) do
      {:ok, bookmark} = result ->
        Bookmarks.broadcast!(result, {:bookmark, :updated})

        :ok

      {:error, error} ->
        Logger.error("Unable to save bookmark #{inspect(error)}")
        {:error, error}
    end
  end
end
