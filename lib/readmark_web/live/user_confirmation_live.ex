defmodule ReadmarkWeb.UserConfirmationLive do
  use ReadmarkWeb, :live_view

  alias Readmark.Accounts

  # TODO: add a user confirmation reminder (flash) in settings
  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div>
      <.header>Confirm Account</.header>

      <.simple_form :let={f} for={:user} id="confirmation_form" phx-submit="confirm_account">
        <.input field={{f, :token}} type="hidden" value={@token} />
        <:actions>
          <.button phx-disable-with="Confirming...">Confirm my account</.button>
        </:actions>
      </.simple_form>

      <p class="text-sm mt-2">
        <.link href={~p"/users/register"}>Register</.link>
        |
        <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, token: params["token"]), temporary_assigns: [token: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        socket = put_flash(socket, :info, "User confirmed successfully.")

        case socket.assigns do
          %{current_user: _user} ->
            {:noreply, redirect(socket, to: ~p"/")}

          _ ->
            {:noreply, redirect(socket, to: ~p"/users/log_in")}
        end

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          _ ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/users/log_in")}
        end
    end
  end
end
