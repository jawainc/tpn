defmodule TpnWeb.Administrator.DashBoardController do
  use TpnWeb, :controller

  def index(conn, _params) do
    conn
    |> render(:index)
  end

  def dash(conn, _params) do
    render(conn, :index)
  end
end
