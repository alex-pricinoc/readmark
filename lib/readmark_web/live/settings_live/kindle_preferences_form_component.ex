defmodule ReadmarkWeb.SettingsLive.KindlePreferencesFormComponent do
  use ReadmarkWeb, :live_component

  import Phoenix.HTML.Form

  alias Readmark.Accounts
  alias Readmark.Workers.ArticleSender
  alias Accounts.User.KindlePreferences

  @impl true
  def update(%{current_user: user, time_zone: time_zone} = assigns, socket) do
    changeset = Accounts.change_user_kindle_preferences(user)
    from_email = Application.get_env(:readmark, :from_email, "contact@example.com")
    job = ArticleSender.get_scheduled_delivery(user)

    next_delivery =
      job &&
        job.scheduled_at
        |> Timex.Timezone.convert(time_zone || user.kindle_preferences.time_zone)
        |> Timex.format!("{RFC1123}")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:from_email, from_email)
     |> assign(:next_delivery, next_delivery)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_kindle_preferences(socket.assigns.current_user, user_params)

    {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :validate))}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_kindle_preferences(socket.assigns.current_user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Updated successfully!")
         |> push_navigate(to: ~p"/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp time_select_options do
    [
      midnight: "00:00:00",
      "1 AM": "01:00:00",
      "2 AM": "02:00:00",
      "3 AM": "03:00:00",
      "4 AM": "04:00:00",
      "5 AM": "05:00:00",
      "6 AM": "06:00:00",
      "7 AM": "07:00:00",
      "8 AM": "08:00:00",
      "9 AM": "09:00:00",
      "10 AM": "10:00:00",
      "11 AM": "11:00:00",
      noon: "12:00:00",
      "1 PM ": "13:00:00",
      "2 PM ": "14:00:00",
      "3 PM ": "15:00:00",
      "4 PM ": "16:00:00",
      "5 PM ": "17:00:00",
      "6 PM ": "18:00:00",
      "7 PM ": "19:00:00",
      "8 PM ": "20:00:00",
      "9 PM ": "21:00:00",
      "10 PM ": "22:00:00",
      "11 PM ": "23:00:00"
    ]
  end
end
