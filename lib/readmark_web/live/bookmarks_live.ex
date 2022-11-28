defmodule ReadmarkWeb.BookmarksLive do
  use ReadmarkWeb, :live_view

  require Logger

  alias Readmark.Bookmarks
  alias Bookmarks.Bookmark

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Bookmarks.subscribe()

    assigns = [
      tags: [],
      bookmarks: Bookmarks.list_bookmarks(),
      reset_counter: 0,
      active_bookmark: nil
    ]

    {:ok, assign(socket, assigns), temporary_assigns: [bookmarks: []]}
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
      if get_in(socket.assigns, [:active_bookmark, Access.key(:id)]) == id do
        push_patch(socket, to: bookmark_path(nil))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-tag", %{"name" => tag}, socket) do
    toggle_tag = fn tags, tag ->
      case tag in tags do
        true -> List.delete(tags, tag)
        false -> List.insert_at(tags, 0, tag)
      end
    end

    tags = toggle_tag.(socket.assigns.tags, tag)

    {:noreply,
     socket
     |> assign(:tags, tags)
     |> assign(:bookmarks, Bookmarks.list_bookmarks(tags: tags))
     |> update(:reset_counter, &(&1 + 1))}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing bookmarks")
    |> assign(:active_bookmark, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    bookmark = Bookmarks.get_bookmark!(id)

    if bookmark.content == nil, do: fetch_article(bookmark)

    socket
    |> assign(:page_title, bookmark.title)
    |> assign(:active_bookmark, bookmark)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    bookmark = Bookmarks.get_bookmark!(id)

    socket
    |> assign(:page_title, bookmark.title)
    |> assign(:bookmark, bookmark)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New bookmark")
    |> assign(:bookmark, %Bookmark{})
  end

  @impl true
  def handle_info({{:bookmark, action}, bookmark}, socket) do
    socket =
      maybe_update_active_bookmark(action, socket, socket.assigns.active_bookmark, bookmark)

    {:noreply, update(socket, :bookmarks, fn bookmarks -> [bookmark | bookmarks] end)}
  end

  @impl true
  def handle_info({:article_fetch_response, content, bookmark}, socket) do
    {:ok, _bookmark} = Bookmarks.update_bookmark(bookmark, %{content: content})
    {:noreply, socket}
  end

  defp fetch_article(bookmark) do
    pid = self()

    Task.Supervisor.start_child(Readmark.TaskSupervisor, fn ->
      Logger.info("Fetching URL: #{bookmark.url}")

      %Readability.Summary{article_html: html, article_text: text} =
        Readability.summarize(bookmark.url)

      content = html || text

      send(pid, {:article_fetch_response, content, bookmark})
    end)
  end

  defp maybe_update_active_bookmark(:updated, socket, active_bookmark, bookmark)
       when active_bookmark.id == bookmark.id,
       do: assign(socket, :active_bookmark, Bookmarks.get_bookmark!(active_bookmark.id))

  defp maybe_update_active_bookmark(_, socket, _, _), do: socket
end
