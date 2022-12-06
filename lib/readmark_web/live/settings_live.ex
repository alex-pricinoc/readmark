defmodule ReadmarkWeb.SettingsLive do
  use ReadmarkWeb, :live_view

  alias Readmark.Accounts
  alias ReadmarkWeb.SettingsLive.UploadFormComponent

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/settings")}
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_changeset, Accounts.change_user_email(user))
      |> assign(:password_changeset, Accounts.change_user_password(user))
      |> assign(:display_name_changeset, Accounts.change_user_display_name(user))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    email_changeset = Accounts.change_user_email(socket.assigns.current_user, user_params)

    socket =
      assign(socket,
        email_changeset: Map.put(email_changeset, :action, :validate),
        email_form_current_password: password
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/settings/confirm_email/#{&1}")
        )

        socket =
          socket
          |> put_flash(
            :info,
            "A link to confirm your email change has been sent to the new address."
          )
          |> push_patch(to: ~p"/settings")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_changeset, Map.put(changeset, :action, :insert))}
    end
  end

  @impl true
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    password_changeset = Accounts.change_user_password(socket.assigns.current_user, user_params)

    {:noreply,
     socket
     |> assign(:password_changeset, Map.put(password_changeset, :action, :validate))
     |> assign(:current_password, password)}
  end

  @impl true
  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        socket =
          socket
          |> assign(:trigger_submit, true)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_changeset, changeset)}
    end
  end

  @impl true
  def handle_event("validate_display_name", %{"user" => user_params}, socket) do
    display_name_changeset =
      Accounts.change_user_display_name(socket.assigns.current_user, user_params)

    {:noreply,
     socket
     |> assign(:display_name_changeset, Map.put(display_name_changeset, :action, :validate))}
  end

  @impl true
  def handle_event("update_display_name", %{"user" => user_params}, socket) do
    case Accounts.update_user_display_name(socket.assigns.current_user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Updated successfully!")
         |> push_navigate(to: ~p"/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, :display_name_changeset, changeset)}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Settings")
  end

  defp apply_action(socket, :change_email, _params) do
    socket
    |> assign(:page_title, "Change Email")
  end

  defp apply_action(socket, :change_display_name, _params) do
    socket
    |> assign(:page_title, "Change Display Name")
  end

  defp apply_action(socket, :change_password, _params) do
    socket
    |> assign(:page_title, "Change Password")
  end
end
