defmodule ReadmarkWeb.ReadingLive.FormComponent do
  use ReadmarkWeb, :live_component

  alias Readmark.Bookmarks
  alias Readmark.ArticleFetcher

  @impl true
  def update(%{action: {:article, article}}, socket) do
    {:ok,
     socket
     |> assign(:loading, false)
     |> assign(:article, article)}
  end

  @impl true
  def update(%{bookmark: bookmark} = assigns, socket) do
    changeset = Bookmarks.change_bookmark(bookmark)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:loading, false)
     |> assign(:article, nil)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"bookmark" => bookmark_params}, socket) do
    changeset =
      socket.assigns.bookmark
      |> Bookmarks.change_bookmark(bookmark_params)
      |> Map.put(:action, :validate)

    socket =
      if should_fetch?(socket.assigns.article, changeset) do
        fetch_article(socket, changeset.changes[:url])
      else
        socket
      end

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"bookmark" => bookmark_params}, socket) do
    save_bookmark(socket, socket.assigns.action, bookmark_params)
  end

  defp save_bookmark(socket, :new, bookmark_params) do
    bookmark_params =
      if article = socket.assigns.article do
        Map.merge(bookmark_params, %{"title" => article.title, "articles" => [article]})
      else
        bookmark_params
      end

    case Bookmarks.create_bookmark(socket.assigns.current_user, bookmark_params) do
      {:ok, _bookmark} ->
        {:noreply,
         socket
         |> put_flash(:info, "Link saved successfully!")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp fetch_article(socket, url) do
    pid = self()

    Task.Supervisor.start_child(Readmark.TaskSupervisor, fn ->
      send_update(pid, __MODULE__,
        id: socket.assigns.id,
        action: {:article, ArticleFetcher.get_or_fetch_article(url)}
      )
    end)

    assign(socket, :loading, true)
  end

  defp should_fetch?(article, changeset) do
    changeset.errors[:url] == nil and
      (article == nil or article.url != changeset.changes[:url])
  end
end
