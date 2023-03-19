defmodule ReadmarkWeb.Layouts do
  use ReadmarkWeb, :html

  embed_templates("layouts/*")

  defp links do
    [
      %{name: :reading, label: "Reading", to: ~p"/reading", icon: "hero-book-open"},
      %{name: :bookmarks, label: "Bookmarks", to: ~p"/bookmarks", icon: "hero-bookmark-square"},
      %{name: :archive, label: "Archive", to: ~p"/archive", icon: "hero-archive-box"},
      %{name: :settings, label: "Settings", to: ~p"/settings", icon: "hero-cog-8-tooth"}
    ]
  end
end
