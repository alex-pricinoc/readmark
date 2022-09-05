defmodule ReadmarkWeb.LayoutView do
  use ReadmarkWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  @endpoint ReadmarkWeb.Endpoint

  def links do
    [
      %{icon: :home, name: :home, label: "Home", to: Routes.home_path(@endpoint, :index)},
      %{
        icon: :pencil_alt,
        name: :notes,
        label: "Notes",
        to: Routes.notes_path(@endpoint, :index)
      },
      %{
        icon: :bookmark,
        name: :bookmarks,
        label: "Bookmarks",
        to: Routes.bookmarks_path(@endpoint, :index)
      }
    ]
  end
end
