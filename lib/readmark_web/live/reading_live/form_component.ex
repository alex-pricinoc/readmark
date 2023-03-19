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
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"bookmark" => bookmark_params}, socket) do
    changeset =
      socket.assigns.bookmark
      |> Bookmarks.change_bookmark(bookmark_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"bookmark" => bookmark_params}, socket) do
    save_bookmark(socket, socket.assigns.action, bookmark_params)
  end

  defp save_bookmark(socket, :new, bookmark_params) do
    case Bookmarks.create_bookmark(socket.assigns.current_user, fetch_article(bookmark_params)) do
      {:ok, bookmark} ->
        notify_parent({:created, bookmark})

        {:noreply,
         socket
         |> put_flash(:info, "Link saved successfully!")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp fetch_article(%{"url" => url} = bookmark_params) do
    if article = ArticleFetcher.fetch_article(url) do
      Map.merge(bookmark_params, %{"title" => article.title, "articles" => [article]})
    else
      bookmark_params
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "bookmark"))
  end

  defp notify_parent(msg), do: send(self(), msg)
end
