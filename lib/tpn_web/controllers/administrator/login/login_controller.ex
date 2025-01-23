defmodule TpnWeb.Administrator.Login.LoginController do
  use TpnWeb, :controller

  alias Tpn.Accounts.Administartors
  alias TpnWeb.AdminAuth
  alias TpnWeb.UserAuth

  def index(conn, _params) do
    conn
    |> put_layout(html: :login)
    |> render(:index)
  end

  def create(conn, %{"login_id" => login_id, "password" => password}) do
    if user = Administartors.get_administrator_by_login_id_and_password(login_id, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> AdminAuth.log_in_user(user)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> render(:index, layout: false, data: %{"login_id" => login_id})
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user("admin-session")
  end
end
