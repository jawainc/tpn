defmodule TpnWeb.Login.LoginController do
  use TpnWeb, :controller

  alias Tpn.Accounts.Users
  alias TpnWeb.UserAuth

  def index(conn, _params) do
    conn
    |> put_layout(html: :login)
    |> render(:index)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    if user = Users.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> render(:index, layout: false, data: %{"email" => email})
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
