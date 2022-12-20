defmodule ReadmarkWeb.BookmarkController do
  use ReadmarkWeb, :controller

  alias Readmark.{Bookmarks, Epub}
  alias Readmark.Workers.ArticleCrawler
  alias Readmark.Accounts.EpubSender

  def new(conn, params) do
    bookmark_params = Map.take(params, ["url", "title"])

    case Bookmarks.create_bookmark(conn.assigns.current_user, bookmark_params) do
      {:ok, _bookmark} ->
        conn
        |> put_flash(:info, "Bookmark created successfully!")
        |> redirect(to: ~p"/bookmarks")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong! Please check the changes below.")
        |> redirect(to: ~p"/bookmarks/new?#{bookmark_params}")
    end
  end

  def reading(conn, %{"url" => url}) do
    article = ArticleCrawler.get_or_fetch_article(url)

    bookmark_params = %{
      "url" => url,
      "title" => article.title,
      "articles" => [article],
      "folder" => "reading"
    }

    case Bookmarks.create_bookmark(conn.assigns.current_user, bookmark_params) do
      {:ok, bookmark} ->
        conn
        |> put_flash(:info, "Link saved successfully!")
        |> redirect(to: ~p"/reading/#{bookmark}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong! Cannot save article.")
        |> redirect(to: ~p"/reading")
    end
  end

  def kindle(conn, %{"url" => url}) do
    article = ArticleCrawler.get_or_fetch_article(url)

    epub = Epub.build([article])

    {:ok, _mail} = EpubSender.deliver_epub(conn.assigns.current_user.kindle_email, epub)

    File.rm!(epub)

    conn
    |> put_flash(:info, "Your article has been sent. You should receive it in a few minutes.")
    |> redirect(to: ~p"/")
  end
end
