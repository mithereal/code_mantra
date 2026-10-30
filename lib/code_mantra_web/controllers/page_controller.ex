defmodule CodeMantraWeb.PageController do
  use CodeMantraWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
