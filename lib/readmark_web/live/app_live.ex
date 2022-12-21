defmodule ReadmarkWeb.AppLive do
  defmodule AppLive do
    @callback bookmark_path(bookmark :: Bookmark.t() | nil) :: String.t()
    @callback assign_title(socket :: Socket.t(), action :: atom()) :: String.t()
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use ReadmarkWeb, :app_view

      alias Readmark.Bookmarks
      alias Bookmarks.Bookmark
      alias Readmark.Workers.ArticleCrawler

      @behaviour AppLive

      @folder opts[:folder]

      @impl true
      def mount(_params, _session, socket) do
        user = socket.assigns.current_user

        if connected?(socket), do: Bookmarks.subscribe(user.id)

        assigns = [
          tags: [],
          version: 0,
          folder: @folder,
          bookmarks: Bookmarks.list_bookmarks(user, folder: @folder),
          active_bookmark: nil
        ]

        {:ok, assign(socket, assigns), temporary_assigns: [bookmarks: []]}
      end

      @impl true
      def handle_params(params, _url, socket) do
        {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      end

      @impl true
      def handle_event("select-tag", %{"name" => tag}, socket) do
        toggle_tag = fn tags, tag ->
          if tag in tags,
            do: List.delete(tags, tag),
            else: List.insert_at(tags, 0, tag)
        end

        tags = toggle_tag.(socket.assigns.tags, tag)

        {:noreply,
         socket
         |> assign(:tags, tags)
         |> list_bookmarks()
         |> update(:version, &(&1 + 1))}
      end

      @impl true
      def handle_event("archive-bookmark", %{"id" => id}, socket) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        new_folder = if bookmark.folder != :archive, do: :archive, else: :bookmarks

        {:ok, bookmark} = Bookmarks.update_bookmark(bookmark, %{folder: new_folder})

        {:noreply, socket}
      end

      @impl true
      def handle_event("delete-bookmark", %{"id" => id}, socket) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        {:ok, _} = Bookmarks.delete_bookmark(bookmark)

        {:noreply, socket}
      end

      defp apply_action(socket, :index, _params) do
        socket
        |> assign_title(:index)
        |> assign(:active_bookmark, nil)
      end

      defp apply_action(socket, :show, %{"id" => id}) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        maybe_fetch_article(bookmark)

        socket
        |> assign(:page_title, bookmark.title)
        |> assign(:active_bookmark, bookmark)
      end

      defp apply_action(socket, :edit, %{"id" => id}) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        socket
        |> assign_title(:edit)
        |> assign(:bookmark, bookmark)
      end

      defp apply_action(socket, :new, bookmark_params) do
        socket
        |> assign_title(:new)
        |> assign(:bookmark_params, bookmark_params)
        |> assign(:bookmark, %Bookmark{})
      end

      @impl true
      def handle_info({{:bookmark, action}, bookmark}, socket) do
        socket =
          maybe_update_active_bookmark(action, socket, socket.assigns.active_bookmark, bookmark)

        {:noreply, update(socket, :bookmarks, fn bookmarks -> [bookmark | bookmarks] end)}
      end

      defp list_bookmarks(socket) do
        %{current_user: user, tags: tags} = socket.assigns

        assign(socket, :bookmarks, Bookmarks.list_bookmarks(user, folder: @folder, tags: tags))
      end

      defp maybe_update_active_bookmark(:updated, socket, active_bookmark, bookmark)
           when active_bookmark.id == bookmark.id do
        user_id = socket.assigns.current_user.id

        assign(socket, :active_bookmark, Bookmarks.get_bookmark!(active_bookmark.id, user_id))
      end

      defp maybe_update_active_bookmark(_, socket, _, _), do: socket

      defp get_article(%Bookmark{articles: [article | _]}), do: article
      defp get_article(_bookmark), do: nil

      defp maybe_fetch_article(%Bookmark{folder: :reading, articles: []} = bookmark) do
        ArticleCrawler.fetch_article(bookmark)
      end

      defp maybe_fetch_article(_bookmark), do: :ok
    end
  end
end
