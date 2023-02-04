defmodule ReadmarkWeb.AppLive.Archive do
  use ReadmarkWeb.AppLive, folder: :archive

  @impl true
  def bookmark_path(_), do: ~p"/archive"

  @impl true
  def assign_title(socket, :index), do: assign(socket, :page_title, "Archived bookmarks")
end
