defmodule ReadmarkWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ReadmarkWeb, :controller
      use ReadmarkWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json]

      import Plug.Conn
      import ReadmarkWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {ReadmarkWeb.Layouts, :live}

      import Phoenix.LiveView,
        except: [
          stream_insert: 3,
          stream_insert: 4
        ]

      def stream_insert(socket, name, item_or_items, opts \\ [])

      def stream_insert(socket, name, items, opts) when is_list(items) do
        Enum.reduce(items, socket, fn item, socket ->
          stream_insert(socket, name, item, opts)
        end)
      end

      def stream_insert(socket, name, item, opts) do
        Phoenix.LiveView.stream_insert(socket, name, item, opts)
      end

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      import Phoenix.Param
      # Core UI components and translation
      import ReadmarkWeb.{CoreComponents, FormComponents}
      import ReadmarkWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ReadmarkWeb.Endpoint,
        router: ReadmarkWeb.Router,
        statics: ~w(assets fonts images favicon.svg robots.txt manifest.json)
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
