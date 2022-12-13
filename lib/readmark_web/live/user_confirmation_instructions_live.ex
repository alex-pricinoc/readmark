defmodule ReadmarkWeb.UserConfirmationInstructionsLive do
  use ReadmarkWeb, :live_view

  alias Readmark.Accounts

  def render(assigns) do
    ~H"""
    <div class="max-w-sm px-2">
      <.header>Resend confirmation instructions</.header>

      <.simple_form :let={f} for={:user} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={{f, :email}} type="email" label="Email" required />
        <:actions>
          <.button phx-disable-with="Sending...">Resend confirmation instructions</.button>
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

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(
       :info,
       "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
     )
     |> redirect(to: ~p"/")}
  end
end
