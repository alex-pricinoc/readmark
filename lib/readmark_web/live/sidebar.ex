defmodule ReadmarkWeb.Sidebar do
  import Phoenix.LiveView

  alias ReadmarkWeb.{HomeLive}

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {HomeLive, _} ->
          :home

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end
end
