defmodule ReadmarkWeb.ReadingLive.FormComponent do
  use ReadmarkWeb, :live_component

  alias Readmark.Bookmarks
  alias Readmark.Workers.ArticleFetcher

  @impl true
  def update(%{bookmark: bookmark} = assigns, socket) do
    changeset = Bookmarks.change_bookmark(bookmark)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"bookmark" => bookmark_params}, socket) do
    changeset =
      socket.assigns.bookmark
      |> Bookmarks.change_bookmark(bookmark_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"bookmark" => bookmark_params}, socket) do
    save_bookmark(socket, socket.assigns.action, bookmark_params)
  end

  defp save_bookmark(socket, :new, bookmark_params) do
    case Bookmarks.create_bookmark(socket.assigns.current_user, fetch_article(bookmark_params)) do
      {:ok, _bookmark} ->
        {:noreply,
         socket
         |> put_flash(:info, "Link saved successfully!")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp fetch_article(%{"url" => url} = bookmark_params) do
    if article = ArticleFetcher.get_article(url) do
      Map.merge(bookmark_params, %{"title" => article.title, "articles" => [article]})
    else
      bookmark_params
    end
  end
end
