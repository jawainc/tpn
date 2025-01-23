defmodule TpnWeb.DashBoardController do
  use TpnWeb, :controller

  def index(conn, _params) do
    conn
    |> render(:index)
  end

  def dash(conn, _params) do
    key = :crypto.strong_rand_bytes(32)
    safe_key = Base.encode64(key)

    conn
    |> put_session(:encryption_key, safe_key)
    |> render(:index)
  end
end
