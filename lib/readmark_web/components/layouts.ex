defmodule ReadmarkWeb.Layouts do
  use ReadmarkWeb, :html
  use ReadmarkWeb, :verified_routes

  embed_templates "layouts/*"

  defp links do
    [
      %{name: :home, label: "Home", to: "/"},
      %{name: :notes, label: "Notes", to: ~p"/notes"},
      %{name: :bookmarks, label: "Bookmarks", to: ~p"/bookmarks"},
      %{name: :settings, label: "Settings", to: ~p"/settings"}
    ]
  end

  attr :name, :string, required: true
  attr :rest, :global

  defp icon(%{name: :home} = assigns), do: ~H|<Heroicons.home {@rest} />|
  defp icon(%{name: :notes} = assigns), do: ~H|<Heroicons.pencil_square {@rest} />|
  defp icon(%{name: :bookmarks} = assigns), do: ~H|<Heroicons.bookmark_square {@rest} />|
  defp icon(%{name: :settings} = assigns), do: ~H|<Heroicons.cog_8_tooth {@rest} />|
end
