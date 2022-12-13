defmodule ReadmarkWeb.AppLive.Bookmarks do
  use ReadmarkWeb.AppLive, folder: :bookmarks

  def bookmark_path(%Bookmark{} = bookmark), do: ~p"/bookmarks/#{bookmark}"
  def bookmark_path(_), do: ~p"/bookmarks"
end
