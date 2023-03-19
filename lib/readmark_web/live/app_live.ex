defmodule ReadmarkWeb.AppLive do
  defmodule AppLive do
    @callback page_title(live_action :: atom()) :: String.t()
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use ReadmarkWeb, :live_view

      alias Readmark.Bookmarks
      alias Bookmarks.{Bookmark, Article}
      alias Readmark.Workers.ArticleFetcher

      @behaviour AppLive

      @folder opts[:folder]

      @impl true
      def mount(params, _session, socket) do
        tags = params["tags"] || []

        %{entries: bookmarks, metadata: metatada} =
          Bookmarks.paginate_bookmarks(socket.assigns.current_user, folder: @folder, tags: tags)

        assigns = [
          tags: tags,
          page_meta: metatada,
          active_bookmark: nil
        ]

        {:ok, socket |> assign(assigns) |> stream(:bookmarks, bookmarks)}
      end

      @impl true
      def handle_params(params, _url, socket) do
        {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      end

      @impl true
      def handle_event("load-more", _params, socket) do
        %{current_user: user, tags: tags, page_meta: page_meta} = socket.assigns

        params = [folder: @folder, tags: tags]

        socket =
          if after_cursor = page_meta.after do
            %{entries: bookmarks, metadata: metadata} =
              Bookmarks.paginate_bookmarks(user, params, after: after_cursor)

            socket |> assign(:page_meta, metadata) |> stream_insert(:bookmarks, bookmarks)
          else
            socket
          end

        {:noreply, socket}
      end

      @impl true
      def handle_event("archive-bookmark", %{"id" => id}, socket) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        new_folder = if bookmark.folder != :archive, do: :archive, else: :bookmarks

        {:ok, bookmark} = Bookmarks.update_bookmark(bookmark, %{folder: new_folder})

        {:noreply, stream_delete(socket, :bookmarks, bookmark)}
      end

      @impl true
      def handle_event("delete-bookmark", %{"id" => id}, socket) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        {:ok, _} = Bookmarks.delete_bookmark(bookmark)

        {:noreply, stream_delete(socket, :bookmarks, bookmark)}
      end

      @impl true
      def handle_info({:created, bookmark}, socket) do
        {:noreply, stream_insert(socket, :bookmarks, bookmark, at: 0)}
      end

      @impl true
      def handle_info({:updated, bookmark}, socket) do
        socket =
          if bookmark.folder == @folder do
            stream_insert(socket, :bookmarks, bookmark)
          else
            stream_delete(socket, :bookmarks, bookmark)
          end

        {:noreply, socket}
      end

      defp apply_action(socket, :index, _params) do
        socket
        |> assign(:page_title, page_title(:index))
        |> assign(:active_bookmark, nil)
      end

      defp apply_action(socket, :show, %{"id" => id}) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        socket
        |> assign(:page_title, bookmark.title)
        |> assign_active_bookmark(bookmark)
      end

      defp apply_action(socket, :edit, %{"id" => id}) do
        bookmark = Bookmarks.get_bookmark!(id, socket.assigns.current_user.id)

        socket
        |> assign(:page_title, page_title(:edit))
        |> assign(:bookmark, bookmark)
      end

      defp apply_action(socket, :new, bookmark_params) do
        socket
        |> assign(:page_title, page_title(:new))
        |> assign(:bookmark, %Bookmark{})
        |> assign(:bookmark_params, bookmark_params)
      end

      defp get_article(%Bookmark{articles: [article | _]}), do: article
      defp get_article(_bookmark), do: nil

      defp assign_active_bookmark(socket, %Bookmark{folder: :reading, articles: []} = bookmark) do
        with %Article{} = article <- ArticleFetcher.fetch_article(bookmark.url),
             {:ok, bookmark} = Bookmarks.update_bookmark(bookmark, %{"articles" => [article]}) do
          assign(socket, :active_bookmark, bookmark)
        else
          _ -> put_flash(socket, :error, "Unable to retrieve article")
        end
      end

      defp assign_active_bookmark(socket, bookmark) do
        assign(socket, :active_bookmark, bookmark)
      end
    end
  end
end
