defmodule ReadmarkWeb.AppLive.Bookmarks do
  use ReadmarkWeb.AppLive, folder: :bookmarks

  @impl true
  def page_title(:index), do: "Listing bookmarks"
  def page_title(:new), do: "Add bookmark"
  def page_title(:edit), do: "Edit bookmark"
end
