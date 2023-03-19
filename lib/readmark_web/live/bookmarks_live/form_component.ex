defmodule ReadmarkWeb.BookmarksLive.FormComponent do
  use ReadmarkWeb, :live_component

  alias Readmark.Bookmarks

  @impl true
  def update(%{bookmark: bookmark, attrs: attrs} = assigns, socket) do
    changeset = Bookmarks.change_bookmark(bookmark, attrs)

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

  defp save_bookmark(socket, :edit, bookmark_params) do
    case Bookmarks.update_bookmark(socket.assigns.bookmark, bookmark_params) do
      {:ok, bookmark} ->
        notify_parent({:updated, bookmark})

        {:noreply,
         socket
         |> put_flash(:info, "Bookmark updated successfully!")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_bookmark(socket, :new, bookmark_params) do
    case Bookmarks.create_bookmark(socket.assigns.current_user, bookmark_params) do
      {:ok, bookmark} ->
        notify_parent({:created, bookmark})

        {:noreply,
         socket
         |> put_flash(:info, "Bookmark created successfully!")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "bookmark"))
  end

  defp notify_parent(msg), do: send(self(), msg)
end
