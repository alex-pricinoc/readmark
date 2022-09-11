defmodule ReadmarkWeb.LayoutComponent do
  @moduledoc """
  Component for rendering content inside layout without full DOM patch.
  """

  # https://github.com/fly-apps/live_beats/blob/master/lib/live_beats_web/live/layout_component.ex

  use ReadmarkWeb, :live_component

  def show_modal(module, attrs) do
    send_update(__MODULE__, id: "layout", show: Enum.into(attrs, %{module: module}))
  end

  def hide_modal do
    send_update(__MODULE__, id: "layout", show: nil)
  end

  def update(%{id: id} = assigns, socket) do
    {:ok, assign(socket, id: id, show: assigns[:show])}
  end

  def render(assigns) do
    ~H"""
    <div class={unless @show, do: "hidden"}>
      <%= if @show do %>
        <.modal title={@show.title} return_to={@show.return_to}>
          <.live_component module={@show.module} {@show} />
        </.modal>
      <% end %>
    </div>
    """
  end
end
