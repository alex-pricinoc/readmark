defmodule ReadmarkWeb.AppLive.Archive do
  use ReadmarkWeb.AppLive, folder: :archive

  @impl true
  def page_title(:index), do: "Archived bookmarks"
end
