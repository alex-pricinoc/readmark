defmodule ReadmarkWeb.BookmarkController do
  use ReadmarkWeb, :controller

  alias Readmark.{Bookmarks, Epub}
  alias Readmark.Workers.ArticleCrawler
  alias Readmark.Accounts.EpubSender
  alias Readmark.Dump

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns.current_user]
    apply(__MODULE__, action_name(conn), args)
  end

  def post(conn, %{"url" => url, "title" => _, "notes" => _} = bookmark_params, current_user) do
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
    article = ArticleCrawler.get_or_fetch_article(url)

    if article != nil do
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

  def kindle(conn, %{"url" => url}, %{kindle_email: email}) when not is_nil(email) do
    article = ArticleCrawler.get_or_fetch_article(url)

    if article != nil do
      epub = Epub.build([article])

      {:ok, _mail} = EpubSender.deliver_epub(email, epub)

      File.rm!(epub)

      redirect(conn, external: url)
    else
      conn
      |> put_flash(:error, "Oops, something went wrong! Cannot fetch article contents.")
      |> redirect(to: ~p"/reading")
    end
  end

  def export(conn, _params, current_user) do
    bookmarks = render_to_string("bookmarks", "netscape", bookmarks: Dump.export(current_user))

    send_download(conn, {:binary, bookmarks}, filename: "bookmarks.html", content_type: "html")
  end

  defp render_to_string(template, format, assigns) do
    Phoenix.Template.render_to_string(ReadmarkWeb.BookmarkHTML, template, format, assigns)
  end
end
