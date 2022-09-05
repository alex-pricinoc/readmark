defmodule ReadmarkWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  def list(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div class={"grow md:grow-0 md:block border-r bg-white md:w-80 xl:w-96 #{@class}"}>
      <div class="flex items-center px-4 py-6">
        <button
          id="show-mobile-sidebar"
          type="button"
          class="p-2 mr-3 rounded-md hover:bg-gray-200 self-start lg:hidden"
          phx-click={show_sidebar()}
        >
          <span class="sr-only">Open sidebar</span>
          <.icon name={:menu} class="w-4 h-4" />
        </button>
        <h1 class="font-semibold capitalize">
          <%= render_slot(@title) %>
        </h1>
      </div>
      <ul class="md:p-2 -space-y-0.5">
        <%= for item <- @items do %>
          <li class="border-b border-gray-100 md:border-none">
            <div class="px-3 py-1.5 cursor-pointer transition md:rounded-md hover:bg-gray-100">
              <%= render_slot(@inner_block, item) %>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def list_detail(assigns) do
    ~H"""
    <div class="flex flex-col flex-1 overflow-y-auto">
      <div
        id="title"
        class="sticky top-0 z-10 flex items-center px-3 py-6 bg-white/90 backdrop-blur transition-shadow [&.reveal]:border-b [&.reveal]:shadow [&.reveal_h1]:opacity-100 [&.reveal_h1]:translate-y-0"
        phx-hook="Reveal"
      >
        <div class="flex items-center">
          <.link to={@back} class="p-2 mr-3 rounded-md hover:bg-gray-200 self-start md:hidden">
            <span class="sr-only">Go back</span>
            <.icon name={:arrow_left} class="w-4 h-4" />
          </.link>
          <h1 class="ml-3 text-md font-bold line-clamp-1 opacity-0 transition-all translate-y-2">
            <%= @title %>
          </h1>
        </div>
      </div>
      <div class="px-10 py-8 flex-1 bg-white">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md b bg-red-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
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
            <.icon name={:x} class="w-4 h-4" />
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
        class="rounded-md bg-green-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
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
            <.icon name={:x} class="w-4 h-4" />
          </button>
        </div>
      </div>
    <% end %>
    """
  end

  def icon(assigns) do
    assigns =
      assigns
      |> assign_new(:outlined, fn -> false end)
      |> assign_new(:class, fn -> "w-4 h-4 inline-block" end)
      |> assign_new(:"aria-hidden", fn -> !Map.has_key?(assigns, :"aria-label") end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons.Outline, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% else %>
      <%= apply(Heroicons.Solid, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% end %>
    """
  end

  def link(assigns) do
    assigns =
      assigns
      |> assign_new(:replace, fn -> false end)
      |> assign_new(:to, fn -> nil end)
      |> assign_new(:link_type, fn -> "live_patch" end)
      |> assign_rest(~w(link_type replace to)a)

    ~H"""
    <.custom_link
      to={@to}
      rest={@rest}
      replace={@replace}
      link_type={@link_type}
      inner_block={@inner_block}
    />
    """
  end

  defp custom_link(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <a
      href={@to}
      data-phx-link="redirect"
      data-phx-link-state="push"
      data-phx-link-state={if @replace, do: "replace", else: "push"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  defp custom_link(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <a
      href={@to}
      data-phx-link="patch"
      data-phx-link-state={if @replace, do: "replace", else: "push"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>
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
    JS.add_class(js, "-translate-x-full", to: "#sidebar")
  end

  def show_sidebar(js \\ %JS{}) do
    JS.remove_class(js, "-translate-x-full", to: "#sidebar")
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

  defp assign_rest(assigns, exclude) do
    assign(assigns, :rest, assigns_to_attributes(assigns, exclude))
  end
end
