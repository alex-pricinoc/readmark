defmodule ReadmarkWeb.AppLive.Reading do
  use ReadmarkWeb.AppLive, folder: :reading

  @impl true
  def page_title(:index), do: "Currently reading"
  def page_title(:new), do: "Add link"
end
