defmodule ReadmarkWeb.BookmarksLive do
  use ReadmarkWeb, :live_view

  alias Readmark.Bookmarks

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Bookmarks")
     |> assign(:bookmarks, Bookmarks.list_bookmarks())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing bookmarks")
    |> assign(:bookmark, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    bookmark = Enum.find(socket.assigns.bookmarks, &(&1.id == id))

    socket
    |> assign(:page_title, bookmark.title)
    |> assign(:bookmark, bookmark)
  end
end
