defmodule ReadmarkWeb.Layouts do
  use ReadmarkWeb, :html

  embed_templates "layouts/*"

  defp links do
    [
      %{name: :reading, label: "Reading", to: ~p"/reading"},
      %{name: :bookmarks, label: "Bookmarks", to: ~p"/bookmarks"},
      %{name: :archive, label: "Archive", to: ~p"/archive"},
      %{name: :settings, label: "Settings", to: ~p"/settings"}
    ]
  end

  attr :name, :string, required: true
  attr :rest, :global

  defp icon(%{name: :reading} = assigns), do: ~H|<Heroicons.book_open {@rest} />|
  defp icon(%{name: :bookmarks} = assigns), do: ~H|<Heroicons.bookmark_square {@rest} />|
  defp icon(%{name: :archive} = assigns), do: ~H|<Heroicons.archive_box {@rest} />|
  defp icon(%{name: :settings} = assigns), do: ~H|<Heroicons.cog_8_tooth {@rest} />|
end
