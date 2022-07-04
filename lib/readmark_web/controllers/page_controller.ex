defmodule ReadmarkWeb.PageController do
  use ReadmarkWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
