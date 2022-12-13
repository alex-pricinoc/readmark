defmodule ReadmarkWeb.PageController do
  use ReadmarkWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/users/log_in")
  end
end
