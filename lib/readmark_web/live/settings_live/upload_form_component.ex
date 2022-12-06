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
       auto_upload: true
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
end
