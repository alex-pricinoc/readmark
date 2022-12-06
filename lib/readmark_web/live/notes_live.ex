defmodule ReadmarkWeb.NotesLive do
  use ReadmarkWeb, :app_view

  alias Readmark.Notes

  @impl true
  def mount(_params, _session, socket) do
    assigns = [
      note: nil,
      page_title: "Notes",
      notes: Notes.list_notes()
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing notes")
    |> assign(:note, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    note = Enum.find(socket.assigns.notes, &(&1.id == id))

    socket
    |> assign(:page_title, note.title)
    |> assign(:note, note)
  end
end
