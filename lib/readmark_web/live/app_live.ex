defmodule ReadmarkWeb.AppLive do
  defmodule AppLive do
    @callback bookmark_path(Readmark.Bookmarks.Bookmark.t() | nil) :: String.t()
    @callback assign_title(Phoenix.LiveView.Socket.t(), atom()) :: Phoenix.LiveView.Socket.t()
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use ReadmarkWeb, :live_view

      require Logger

      alias Readmark.Bookmarks
      alias Bookmarks.{Bookmark, Article}
      alias Readmark.Workers.ArticleFetcher

      @behaviour AppLive

      @folder opts[:folder]

      @impl true
      def mount(_params, _session, socket) do
        user = socket.assigns.current_user

        if connected?(socket), do: Bookmarks.subscribe(user.id)

        %{entries: bookmarks, metadata: metatada} =
          Bookmarks.paginate_bookmarks(user, folder: @folder)

        assigns = [
          tags: [],
          folder: @folder,
          phx_update: "replace",
          bookmarks: bookmarks,
          page_meta: metatada,
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

        user = socket.assigns.current_user
        tags = toggle_tag.(socket.assigns.tags, tag)

        %{entries: bookmarks, metadata: metadata} =
          Bookmarks.paginate_bookmarks(user, folder: @folder, tags: tags)

        {:noreply,
         socket
         |> assign(:tags, tags)
         |> assign(:page_meta, metadata)
         |> replace_bookmarks(bookmarks)}
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

      @impl true
      def handle_event("load-more", _params, socket) do
        %{current_user: user, tags: tags, page_meta: page_meta} = socket.assigns

        params = [folder: @folder, tags: tags]

        socket =
          if after_cursor = page_meta.after do
            %{entries: bookmarks, metadata: metadata} =
              Bookmarks.paginate_bookmarks(user, params, after: after_cursor)

            socket |> append_bookmarks(bookmarks) |> assign(:page_meta, metadata)
          else
            socket
          end

        {:noreply, socket}
      end

      defp apply_action(socket, :index, _params) do
        socket
        |> assign_title(:index)
        |> assign(:active_bookmark, nil)
      end

      defp apply_action(socket, :show, %{"id" => id}) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        socket = maybe_fetch_article(socket, bookmark)

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

        {:noreply, prepend_bookmark(socket, bookmark)}
      end

      defp maybe_update_active_bookmark(:updated, socket, active_bookmark, bookmark)
           when active_bookmark.id == bookmark.id do
        user_id = socket.assigns.current_user.id

        assign(socket, :active_bookmark, Bookmarks.get_bookmark!(active_bookmark.id, user_id))
      end

      defp maybe_update_active_bookmark(_, socket, _, _), do: socket

      defp get_article(%Bookmark{articles: [article | _]}), do: article
      defp get_article(_bookmark), do: nil

      defp maybe_fetch_article(socket, %Bookmark{folder: :reading, articles: []} = bookmark) do
        with %Article{} = article <- ArticleFetcher.fetch_article(bookmark.url),
             {:ok, _bookmark} = Bookmarks.update_bookmark(bookmark, %{"articles" => [article]}) do
          socket
        else
          _ ->
            put_flash(socket, :error, "Unable to retrieve article")
        end
      end

      defp maybe_fetch_article(socket, _bookmark), do: socket

      defp replace_bookmarks(socket, bookmarks) do
        socket
        |> assign(:phx_update, "replace")
        |> assign(:bookmarks, bookmarks)
      end

      defp prepend_bookmark(socket, bookmark) do
        socket
        |> assign(:phx_update, "prepend")
        |> update(:bookmarks, fn bookmarks -> [bookmark | bookmarks] end)
      end

      defp append_bookmarks(socket, bookmarks) do
        socket
        |> assign(:phx_update, "append")
        |> assign(:bookmarks, bookmarks)
      end
    end
  end
end
