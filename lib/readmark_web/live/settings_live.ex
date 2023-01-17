defmodule ReadmarkWeb.SettingsLive do
  use ReadmarkWeb, :app_view

  alias Readmark.Accounts
  alias ReadmarkWeb.SettingsLive.{UploadFormComponent, KindlePreferencesFormComponent}
  alias Readmark.{Bookmarks, Epub}
  alias Accounts.EpubSender

  # TODO: Move account settings to a live component
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

    assigns = [
      current_password: nil,
      email_form_current_password: nil,
      current_email: user.email,
      email_changeset: Accounts.change_user_email(user),
      password_changeset: Accounts.change_user_password(user),
      display_name_changeset: Accounts.change_user_display_name(user),
      trigger_submit: false,
      time_zone: get_connect_params(socket)["timezone"]
    ]

    {:ok, assign(socket, assigns)}
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
     assign(socket, :display_name_changeset, Map.put(display_name_changeset, :action, :validate))}
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

  @impl true
  def handle_event("send-articles", _params, socket) do
    pid = self()

    Task.Supervisor.start_child(Readmark.TaskSupervisor, fn ->
      {epub, delete_gen_files} = Enum.flat_map(bookmarks, & &1.articles) |> Epub.build()

      {:ok, _mail} = EpubSender.deliver_epub(user.kindle_email, epub)

      delete_gen_files.()

      _archived =
        Enum.map(bookmarks, fn b ->

  @impl true
  def handle_info({:articles_sent, count}, socket) do
    info =
      if count > 0,
        do: "Your articles have been sent. You should receive them in a few minutes.",
        else: "You don't have any unread articles. Add some on reading page."

    {:noreply, socket |> put_flash(:info, info) |> assign(:articles_sending?, false)}
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

  defp apply_action(socket, :update_kindle_preferences, _params) do
    socket
    |> assign(:page_title, "Change Kindle Preferences")
  end

  defp bookmarklet() do
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

  defp kindle() do
    """
    javascript: document.location =
    "#{url(~p"/_/v1/kindle")}?url=" +
    encodeURIComponent(location.href)
    """
  end

  defp reading() do
    """
    javascript: document.location =
    "#{url(~p"/_/v1/reading")}?url=" +
    encodeURIComponent(location.href)
    """
  end
end
