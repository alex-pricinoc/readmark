defmodule ReadmarkWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  import ReadmarkWeb.BaseComponents

  alias Phoenix.LiveView.JS

  alias ReadmarkWeb.Router.Helpers, as: Routes

  alias ReadmarkWeb.{BookmarksLive, LayoutComponent}
  alias Readmark.Bookmarks.Bookmark

  @endpoint ReadmarkWeb.Endpoint

  def return_to_bookmark(%Bookmark{} = bookmark),
    do: Routes.bookmarks_path(@endpoint, :show, bookmark)

  def return_to_bookmark(_), do: Routes.bookmarks_path(@endpoint, :index)

  def list(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:items, fn -> [] end)
      |> assign_new(:action, fn -> [] end)

    ~H"""
    <div
      id="list"
      class={"grow overflow-y-auto md:grow-0 md:block border-r bg-white md:w-80 xl:w-96 #{@class}"}
      phx-hook="Reveal"
    >
      <header class="z-10 sticky h-20 -top-8 flex items-center bg-white/90 backdrop-blur reveal:shadow-md">
        <div class="sticky top-0 h-12 px-4 flex flex-1 items-center">
          <.show_sidebar_button class="mr-3 lg:hidden" />

          <h1 class="font-semibold capitalize">
            <%= render_slot(@title) %>
          </h1>

          <%= for action <- @action do %>
            <%= render_slot(action) %>
          <% end %>
        </div>
      </header>
      <%= unless @items == [] do %>
        <ul class="md:p-2 -space-y-0.5">
          <%= for item <- @items do %>
            <li class="border-b md:border-none border-gray-100">
              <%= render_slot(@inner_block, item) %>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  def list_detail(assigns) do
    ~H"""
    <div id="list-detail" class="flex flex-col grow overflow-y-auto" phx-hook="Reveal">
      <header class="z-10 sticky h-20 -top-8 flex shrink-0 items-center bg-white/90 backdrop-blur transition-shadow reveal:shadow-md">
        <div class="sticky top-0 h-12 px-4 flex flex-1 items-center">
          <.icon_button
            to={@back}
            link_type="live_patch"
            class="mr-3 md:hidden"
            label="Go back"
            icon={:arrow_left}
          />
          <h1 class="ml-3 text-md font-bold line-clamp-1 opacity-0 transition-all translate-y-2 reveal:opacity-100 reveal:translate-y-0">
            <%= @title %>
          </h1>
        </div>
      </header>
      <div class="px-6 sm:px-10 py-3 sm:py-6 flex-1 bg-white">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def show_sidebar_button(assigns) do
    assigns = assign_rest(assigns)

    ~H"""
    <.icon_button
      id="show-mobile-sidebar"
      label="Open sidebar"
      icon={:menu}
      phx-click={show_sidebar()}
      {@rest}
    />
    """
  end

  def close_sidebar_button(assigns) do
    assigns = assign_rest(assigns)

    ~H"""
    <.icon_button label="Close sidebar" icon={:x} phx-click={hide_sidebar()} {@rest} />
    """
  end

  def circle(assigns) do
    assigns = assign_rest(assigns)

    ~H"""
    <svg width="2" height="2" aria-hidden="true" fill="currentColor" {@rest}>
      <circle cx="1" cy="1" r="1" />
    </svg>
    """
  end

  def modal(assigns) do
    assigns =
      assigns
      |> assign_rest(~w(title return_to)a)

    ~H"""
    <div id="modal" {@rest} phx-remove={hide_modal()}>
      <div
        id="modal-overlay"
        class="fixed inset-0 z-50 transition-opacity bg-gray-900 fade-in bg-opacity-30"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 z-50 flex items-center justify-center px-4 my-4 overflow-hidden transform sm:px-6"
        role="dialog"
        aria-modal="true"
      >
        <div
          id="modal-content"
          class="max-w-md fade-in-scale w-full max-h-full overflow-auto bg-white rounded shadow-lg"
          phx-key="escape"
          phx-click-away={hide_modal()}
          phx-window-keydown={hide_modal()}
        >
          <!-- TODO: remove when live_view 0.18 is released -->
          <.link to={@return_to} data-modal-return class="hidden"></.link>
          <!-- Header -->
          <div class="px-5 py-3 border-b border-gray-100">
            <div class="flex items-center justify-between">
              <div class="font-semibold text-gray-800">
                <%= @title %>
              </div>
              <.link
                link_type="button"
                phx-click={hide_modal()}
                class="text-gray-400 hover:text-gray-500"
              >
                <div class="sr-only">Close</div>
                <.icon name={:x} />
              </.link>
            </div>
          </div>
          <!-- Content -->
          <div class="p-5">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.remove_class("fade-in", to: "#modal-overlay")
    |> JS.hide(
      transition: {
        "ease-in duration-200",
        "opacity-100",
        "opacity-0"
      },
      to: "#modal-overlay"
    )
    |> JS.hide(
      transition: {
        "ease-in duration-200",
        "opacity-100 translate-y-0 md:scale-100",
        "opacity-0 translate-y-4 md:translate-y-0 md:scale-95"
      },
      to: "#modal-content"
    )
    |> JS.dispatch("click", to: "#modal [data-modal-return]")
  end

  def show_bookmark_modal(%{assigns: assigns} = socket) do
    LayoutComponent.show_modal(BookmarksLive.FormComponent, %{
      id: assigns.bookmark.id || :new,
      title: assigns.bookmark.title || "Add New bookmark",
      action: assigns.live_action,
      bookmark: assigns.bookmark,
      return_to: return_to_bookmark(assigns[:active_bookmark])
    })

    socket
  end

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-red-50 p-3 sm:p-4 fixed top-1 right-1 sm:w-96 fade-in-scale z-50"
        phx-hook="Flash"
        phx-click={
          JS.push("lv:clear-flash")
          |> JS.remove_class("fade-in-scale", to: "#flash")
          |> hide("#flash")
        }
      >
        <div class="flex justify-between items-center space-x-3 text-red-700">
          <.icon name={:exclamation_circle} class="w-5 w-5" />
          <p class="flex-1 text-sm font-medium" role="alert">
            <%= live_flash(@flash, @kind) %>
          </p>
          <button
            type="button"
            class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50 focus:ring-red-600"
          >
            <.icon name={:x} />
          </button>
        </div>
      </div>
    <% end %>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-green-50 p-3 sm:p-4 fixed top-1 right-1 sm:w-96 fade-in-scale z-50"
        phx-click={JS.push("lv:clear-flash") |> JS.remove_class("fade-in-scale") |> hide("#flash")}
        phx-value-key="info"
        phx-hook="Flash"
      >
        <div class="flex justify-between items-center space-x-3 text-green-700">
          <.icon name={:check_circle} class="w-5 h-5" />
          <p class="flex-1 text-sm font-medium" role="alert">
            <%= live_flash(@flash, @kind) %>
          </p>
          <button
            type="button"
            class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600"
          >
            <.icon name={:x} />
          </button>
        </div>
      </div>
    <% end %>
    """
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: "#sidebar-overlay", transition: "fade-out")
    |> JS.hide(
      to: "#sidebar",
      transition: {"transition duration-200 transform-gpu", "translate-x-0", "-translate-x-full"}
    )
  end

  def show_sidebar(js \\ %JS{}) do
    js
    |> JS.show(to: "#sidebar-overlay", transition: "fade-in")
    |> JS.show(
      to: "#sidebar",
      transition: {"transition duration-200 transform-gpu", "-translate-x-full", "translate-x-0"}
    )
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.

      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end

  def focus(js \\ %JS{}, parent, to) do
    JS.dispatch(js, "js:focus", to: to, detail: %{parent: parent})
  end

  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end

  @hour 60
  @day @hour * 24
  @week @day * 7
  @month @day * 30
  @year @day * 365

  def format_time(%DateTime{} = time, now \\ DateTime.utc_now()) do
    diff = DateTime.diff(now, time, :minute)

    cond do
      diff <= 5 -> "just now"
      diff <= @hour -> "#{diff}m ago"
      diff <= @day -> "#{div(diff, @hour)}h ago"
      diff <= @day * 2 -> "yesterday"
      diff <= @week -> "#{div(diff, @day)}d ago"
      diff <= @month -> "#{div(diff, @week)}w ago"
      diff <= @year -> "#{div(diff, @month)}mo ago"
      true -> "#{div(diff, @year)}y ago"
    end
  end

  @spec get_domain(String.t()) :: String.t()
  def get_domain(url), do: URI.parse(url).host

  def list_input_value(form, field) do
    value_to_string(Phoenix.HTML.Form.input_value(form, field))
  end

  defp value_to_string(list) when is_list(list), do: Enum.join(list, " ")
  defp value_to_string(value), do: value
end
