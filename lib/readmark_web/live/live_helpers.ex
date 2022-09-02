defmodule ReadmarkWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

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

  defp assign_rest(assigns, exclude) do
    assign(assigns, :rest, assigns_to_attributes(assigns, exclude))
  end
end
