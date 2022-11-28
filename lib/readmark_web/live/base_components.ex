defmodule ReadmarkWeb.BaseComponents do
  use Phoenix.Component

  import Phoenix.HTML.Form

  # TODO: remove when live_view 0.18 is released
  def assign_rest(assigns, exclude \\ []) do
    assign(assigns, :rest, assigns_to_attributes(assigns, exclude))
  end

  def form_label(assigns) do
    base_classes = "text-sm block text-gray-900 mb-0.5 sm:mb-2 font-medium"

    error_class = if has_error?(assigns), do: "has-error", else: ""

    assigns =
      assigns
      |> assign_rest(~w(form field)a)
      |> assign_new(:classes, fn -> [base_classes, error_class] end)

    ~H"""
    <%= label(@form, @field, [class: @classes, phx_feedback_for: input_name(@form, @field)] ++ @rest) %>
    """
  end

  def text_input(assigns) do
    assigns = assign_input_defaults(assigns, text_input_classes(has_error?(assigns)))

    ~H"""
    <%= text_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: input_name(@form, @field)] ++ @rest
    ) %>
    """
  end

  def url_input(assigns) do
    assigns = assign_input_defaults(assigns, text_input_classes(has_error?(assigns)))

    ~H"""
    <%= url_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: input_name(@form, @field)] ++ @rest
    ) %>
    """
  end

  defp assign_input_defaults(assigns, base_classes) do
    assigns
    |> assign_new(:type, fn -> "text" end)
    |> assign_rest(~w(class form field type)a)
    |> assign_new(:classes, fn -> [base_classes, assigns[:class]] end)
  end

  defp text_input_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} border-gray-300 focus:border-primary-500 focus:ring-primary-500 sm:text-sm block disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm w-full rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500"
  end

  def form_field_error(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)
    translate_error = &ReadmarkWeb.ErrorHelpers.translate_error/1

    ~H"""
    <div class={@class}>
      <%= for error <- Keyword.get_values(@form.errors, @field) do %>
        <div
          class="text-xs italic text-red-500 invalid-feedback"
          phx-feedback-for={input_name(@form, @field)}
        >
          <%= translate_error.(error) %>
        </div>
      <% end %>
    </div>
    """
  end

  def button(assigns) do
    assigns =
      assigns
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:size, fn -> "md" end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:color, fn -> "primary" end)
      |> assign_new(:icon, fn -> false end)
      |> assign_new(:classes, &button_classes/1)
      |> assign_rest(~w(classes disabled size color icon class label)a)

    ~H"""
    <button class={@classes} disabled={@disabled} {@rest}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </button>
    """
  end

  defp button_classes(opts) do
    base_classes =
      "font-medium rounded-md inline-flex items-center justify-center border focus:outline-none transition duration-150 ease-in-out"

    color_css =
      case opts[:color] do
        "primary" ->
          "border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800 focus:shadow-outline-primary"

        "secondary" ->
          "border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-700 focus:bg-secondary-700 active:bg-secondary-800 focus:shadow-outline-secondary"
      end

    size_css =
      case opts[:size] do
        "xs" -> "text-xs leading-4 px-2.5 py-1.5"
        "sm" -> "text-sm leading-4 px-3 py-2"
        "md" -> "text-sm leading-5 px-4 py-2"
        "lg" -> "text-base leading-6 px-4 py-2"
        "xl" -> "text-base leading-6 px-6 py-3"
      end

    icon_css = if opts[:icon], do: "flex gap-2 items-center whitespace-nowrap", else: ""

    disabled_css = if opts[:disabled], do: "disabled cursor-not-allowed opacity-50", else: ""

    [
      base_classes,
      color_css,
      size_css,
      disabled_css,
      icon_css,
      opts.class
    ]
  end

  def icon_button(assigns) do
    base_classes = "p-2 rounded-md transition-colors hover:bg-gray-200"

    assigns =
      assigns
      |> assign_rest(~w(class label)a)

    ~H"""
    <.link class={[base_classes, assigns[:class]]} {@rest}>
      <span class="sr-only"><%= @label %></span>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def spinner(assigns) do
    base_classes = "animate-spin h-6 w-6"
    show_class = if assigns[:show] == false, do: "hidden", else: ""

    assigns =
      assigns
      |> assign_new(:classes, fn -> [base_classes, show_class] end)
      |> assign_rest(~w(classes size class show)a)

    ~H"""
    <svg {@rest} class={@classes} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
    """
  end

  def icon(assigns) do
    assigns =
      assigns
      |> assign_new(:outlined, fn -> false end)
      |> assign_new(:class, fn -> "w-4 h-4" end)
      |> assign_new(:"aria-hidden", fn -> !Map.has_key?(assigns, :"aria-label") end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons.Outline, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% else %>
      <%= apply(Heroicons.Solid, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% end %>
    """
  end

  # TODO: remove when live_view 0.18 is released
  def link(assigns) when not is_map_key(assigns, :rest) do
    assigns
    |> assign_new(:replace, fn -> false end)
    |> assign_new(:patch, fn -> nil end)
    |> assign_new(:navigate, fn -> nil end)
    |> assign_rest(~w(replace patch navigate)a)
    |> link
  end

  def link(%{navigate: to} = assigns) when is_binary(to) do
    ~H"""
    <a
      href={@navigate}
      data-phx-link="redirect"
      data-phx-link-state={if @replace, do: "replace", else: "push"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def link(%{patch: to} = assigns) when is_binary(to) do
    ~H"""
    <a
      href={@patch}
      data-phx-link="patch"
      data-phx-link-state={if @replace, do: "replace", else: "push"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def link(%{} = assigns) do
    ~H"""
    <a href="#" {@rest}><%= render_slot(@inner_block) %></a>
    """
  end

  defp has_error?(%{form: form, field: field}) do
    case Keyword.get_values(form.errors, field) do
      [] -> false
      _ -> true
    end
  end

  defp has_error?(_), do: false
end
