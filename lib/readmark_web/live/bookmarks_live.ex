defmodule ReadmarkWeb.BookmarksLive do
  use ReadmarkWeb, :live_view

  alias Readmark.Bookmarks
  alias Bookmarks.Bookmark

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

  @impl true
  def handle_event("delete-bookmark", %{"id" => id}, socket) do
    bookmark = Bookmarks.get_bookmark!(id)
    {:ok, _} = Bookmarks.delete_bookmark(bookmark)

    socket =
      if socket.assigns[:active_bookmark] == bookmark do
        assign(socket, :active_bookmark, nil)
      else
        socket
      end

    {:noreply, assign(socket, :bookmarks, Bookmarks.list_bookmarks())}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing bookmarks")
    |> assign(:active_bookmark, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    bookmark = Enum.find(socket.assigns.bookmarks, &(&1.id == id))

    socket
    |> assign(:page_title, bookmark.title)
    |> assign(:active_bookmark, bookmark)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    bookmark = Enum.find(socket.assigns.bookmarks, &(&1.id == id))

    socket
    |> assign(:page_title, bookmark.title)
    |> assign(:bookmark, bookmark)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New bookmark")
    |> assign(:bookmark, %Bookmark{})
  end
end
