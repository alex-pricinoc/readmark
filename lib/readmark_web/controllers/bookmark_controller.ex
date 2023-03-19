defmodule ReadmarkWeb.BookmarkController do
  use ReadmarkWeb, :controller

  require Logger

  alias Readmark.{Bookmarks, Dump}
  alias Bookmarks.Article
  alias Readmark.Workers.{ArticleFetcher, ArticleSender}

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns.current_user]
    apply(__MODULE__, action_name(conn), args)
  end

  def post(conn, %{"url" => url, "title" => _} = bookmark_params, current_user) do
    case Bookmarks.create_bookmark(current_user, bookmark_params) do
      {:ok, _bookmark} ->
        conn
        |> redirect(external: url)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong! Please check the changes below.")
        |> redirect(to: ~p"/bookmarks/new?#{bookmark_params}")
    end
  end

  def reading(conn, %{"url" => url}, current_user) do
    if article = ArticleFetcher.fetch_article(url) do
      bookmark_params = %{
        "url" => url,
        "title" => article.title,
        "articles" => [article],
        "folder" => "reading"
      }

      case Bookmarks.create_bookmark(current_user, bookmark_params) do
        {:ok, _bookmark} ->
          conn
          |> redirect(external: url)

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Oops, something went wrong! Cannot save article.")
          |> redirect(to: ~p"/reading")
      end
    else
      conn
      |> put_flash(:error, "Oops, something went wrong! Cannot fetch article contents.")
      |> redirect(to: ~p"/reading")
    end
  end

  def kindle(conn, %{"url" => url}, user) do
    with %Article{} = article <- ArticleFetcher.fetch_article(url),
         {:ok, 1} = ArticleSender.deliver_kindle_compilation(user, [article]) do
      redirect(conn, external: url)
    else
      error ->
        Logger.error("An error has occured while delivering articles: #{error}")

        conn
        |> put_flash(:error, "Oops, something went wrong!")
        |> redirect(to: ~p"/reading")
    end
  end

  def export(conn, _params, current_user) do
    bookmarks =
      Phoenix.Template.render_to_string(ReadmarkWeb.BookmarkHTML, "bookmarks", "netscape",
        bookmarks: Dump.export(current_user)
      )

    send_download(conn, {:binary, bookmarks}, filename: "bookmarks.html", content_type: "html")
  end
end
