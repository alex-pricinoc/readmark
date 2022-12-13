defmodule ReadmarkWeb.AppLive.Archive do
  use ReadmarkWeb.AppLive, folder: :archive

  def bookmark_path(%Bookmark{} = bookmark), do: ~p"/archive/#{bookmark}"
  def bookmark_path(_), do: ~p"/archive"
end
