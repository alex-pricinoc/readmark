defmodule ReadmarkWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use ReadmarkWeb, :verified_routes

  import ReadmarkWeb.Gettext

  alias Phoenix.LiveView.JS

  embed_templates "core_components/*"

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid an mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns)

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      phx-hook="Flash"
      class={[
        "fixed top-2 right-2 w-[19rem] sm:w-96 z-50 rounded-lg p-3 ring-1 shadow shadow-zinc-900/5",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[
      "mb-6 sm:mb-10",
      @actions != [] && "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div :if={@actions != []} class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, default: nil

  slot :header, required: true
  slot :inner_block, required: true

  def container(assigns) do
    ~H"""
    <div id={@id} class={[@class, "bg-white overflow-auto h-screen"]} phx-hook="Open">
      <header
        class={[
          "z-10 sticky h-20 -top-8 flex items-center",
          "px-4 bg-white/90 backdrop-blur transition-shadow open:shadow-md"
        ]}
        phx-click={JS.dispatch("js:scrolltop", to: "##{@id}")}
      >
        <div class="sticky top-0 h-12 flex flex-1 items-center">
          <%= render_slot(@header) %>
        </div>
      </header>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :items, :list, required: true

  attr :item_id, :any,
    default: &__MODULE__.item_id/1,
    doc: "the function for generating the item id"

  attr :item_click, :any, default: nil, doc: "the function for handling phx-click on each item"

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def bookmark_list(assigns) do
    ~H"""
    <ul
      id={@id}
      phx-update="stream"
      class={["relative divide-y md:divide-y-0 divide-zinc-100 text-sm leading-relaxed", @class]}
    >
      <li
        :for={item <- @items}
        id={@item_id.(item)}
        phx-click={@item_click && @item_click.(item)}
        class={[
          "flex flex-col px-3 py-1.5 transition-colors duration-75 md:rounded-xl",
          @item_click && "hover:cursor-pointer hover:bg-zinc-50"
        ]}
      >
        <%= render_slot(@inner_block, item) %>
      </li>
    </ul>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(patch phx-click method href)
  attr :label, :string, required: true

  slot :inner_block, required: true

  def icon_button(assigns) do
    ~H"""
    <.link
      aria-label={@label}
      class={["p-2 rounded-lg transition-colors hover:bg-zinc-50", @class]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  attr :rest, :global

  def show_sidebar_button(assigns) do
    ~H"""
    <.icon_button label="Open sidebar" phx-click={show_sidebar()} {@rest}>
      <.icon name="hero-bars-3-solid" class="h-5 w-5" />
    </.icon_button>
    """
  end

  attr :rest, :global

  def close_sidebar_button(assigns) do
    ~H"""
    <.icon_button label="Close sidebar" phx-click={hide_sidebar()} {@rest}>
      <.icon name="hero-x-mark-solid" class="h-5 w-5" />
    </.icon_button>
    """
  end

  @doc """
  Renders a back navigation link.
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left" class="w-3 h-3 stroke-current inline" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  def spinner(assigns) do
    ~H"""
    <svg
      class="animate-spin h-5 w-5 text-gray-400"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global

  def overlay(assigns) do
    ~H"""
    <div
      {@rest}
      class={["fixed inset-0 bg-zinc-50/90 transition-opacity hidden", @class]}
      aria-hidden="true"
    />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-opacity ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      time: 200,
      transition: {"transition-opacity ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", time: 200, transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def show_sidebar(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#sidebar-overlay",
      time: 300,
      transition: {"transition-opacity ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#sidebar",
      time: 300,
      transition:
        {"transition-transform ease-out-cubic duration-300", "-translate-x-full", "translate-x-0"}
    )
  end

  def hide_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#sidebar-overlay",
      time: 200,
      transition: {"transition-opacity ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#sidebar",
      time: 200,
      transition:
        {"transition-transform ease-in duration-200", "translate-x-0", "-translate-x-full"}
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

  ## Helper functions

  def get_domain(url), do: URI.parse(url).host

  def format_date(%Date{} = date), do: Calendar.strftime(date, "%B %-d, %Y")
  def format_time(%DateTime{} = datetime), do: Timex.from_now(datetime)

  def item_id({id, _}), do: id
end
