defmodule ReadmarkWeb.AppLive.Reading do
  use ReadmarkWeb.AppLive, folder: :reading

  @impl true
  def bookmark_path(%Bookmark{} = bookmark), do: ~p"/reading/#{bookmark}"
  def bookmark_path(_), do: ~p"/reading"
end
