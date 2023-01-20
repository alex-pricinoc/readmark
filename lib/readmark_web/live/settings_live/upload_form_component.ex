defmodule ReadmarkWeb.SettingsLive.UploadFormComponent do
  use ReadmarkWeb, :live_component

  alias Readmark.Dump

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(imported: [])
     |> allow_upload(:bookmarks,
       accept: ~w(.html),
       auto_upload: true,
       # Drag and drop, max_entries: 1 stops accepting input. https://github.com/phoenixframework/phoenix_live_view/issues/2392
       max_entries: 1
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    [imported] =
      consume_uploaded_entries(socket, :bookmarks, fn %{path: path}, _entries ->
        bookmarks = Dump.import(socket.assigns.current_user, File.read!(path))
        {:ok, bookmarks}
      end)

    {:noreply, update(socket, :imported, &(&1 ++ imported))}
  end

  defp valid?(%{entries: [_ | _], errors: []}), do: true
  defp valid?(_), do: false

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(_), do: "Something went wrong"
end
