defmodule ReadmarkWeb.AppLive.Bookmarks do
  use ReadmarkWeb.AppLive, folder: :bookmarks

  @impl true
  def bookmark_path(_), do: ~p"/bookmarks"

  @impl true
  def assign_title(socket, :index), do: assign(socket, :page_title, "Listing bookmarks")
  def assign_title(socket, :new), do: assign(socket, :page_title, "Add bookmark")
  def assign_title(socket, :edit), do: assign(socket, :page_title, "Edit bookmark")
end
