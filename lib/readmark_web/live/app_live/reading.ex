defmodule ReadmarkWeb.AppLive.Reading do
  use ReadmarkWeb.AppLive, folder: :reading

  @impl true
  def bookmark_path(%Bookmark{} = bookmark), do: ~p"/reading/#{bookmark}"
  def bookmark_path(_), do: ~p"/reading"

  @impl true
  def assign_title(socket, :index), do: assign(socket, :page_title, "Currently reading")
  def assign_title(socket, :new), do: assign(socket, :page_title, "Add link")
  def assign_title(socket, :edit), do: assign(socket, :page_title, "Edit link")
end
