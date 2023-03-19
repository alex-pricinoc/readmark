defmodule ReadmarkWeb.SettingsLive do
  use ReadmarkWeb, :live_view

  alias Readmark.Accounts
  alias Readmark.Workers.ArticleSender
  alias ReadmarkWeb.SettingsLive.{UploadFormComponent, KindlePreferencesFormComponent}

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
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    assigns = [
      current_password: nil,
      email_form_current_password: nil,
      current_email: user.email,
      email_form: to_form(email_changeset),
      password_form: to_form(password_changeset),
      trigger_submit: false,
      time_zone: get_connect_params(socket)["timezone"]
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
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

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl true
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  @impl true
  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("send-articles", _params, socket) do
    info =
      case ArticleSender.deliver_kindle_compilation(socket.assigns.current_user) do
        {:ok, 0} ->
          "You don't have any unread articles."

        {:ok, _sent} ->
          "Your articles have been sent to your kindle. You should receive them in a few minutes."

        {:error, _error} ->
          "Something went wrong. "
      end

    {:noreply, socket |> put_flash(:info, info)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Settings")
  end

  defp apply_action(socket, :change_email, _params) do
    socket
    |> assign(:page_title, "Change Email")
  end

  defp apply_action(socket, :change_password, _params) do
    socket
    |> assign(:page_title, "Change Password")
  end

  defp apply_action(socket, :change_kindle_preferences, _params) do
    socket
    |> assign(:page_title, "Change Kindle Preferences")
  end

  defp bookmarklet do
    """
    javascript: document.location =
      "#{url(~p"/_/v1/post")}?url=" +
      encodeURIComponent(window.location.href) +
      "&title=" +
      encodeURIComponent(document.title) +
      "&notes=" +
      encodeURIComponent(document.getSelection().toString());
    """
  end

  defp kindle do
    """
    javascript: document.location =
    "#{url(~p"/_/v1/kindle")}?url=" +
    encodeURIComponent(location.href)
    """
  end

  defp reading do
    """
    javascript: document.location =
    "#{url(~p"/_/v1/reading")}?url=" +
    encodeURIComponent(location.href)
    """
  end
end
