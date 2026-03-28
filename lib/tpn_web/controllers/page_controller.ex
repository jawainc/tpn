defmodule TpnWeb.PageController do
  use TpnWeb, :controller

  alias Tpn.Accounts

  def home(conn, _params) do
    # Check if user token exists in session or cookies
    user_token =
      get_session(conn, :user_token) ||
        get_remember_me_cookie(conn)

    if user_token do
      # Try to get user from token
      case Accounts.get_user_by_session_token(user_token) do
        {:ok, _user} ->
          # User is logged in, redirect to dashboard
          redirect(conn, to: "/dashboard")

        _ ->
          # Token is invalid, redirect to login
          redirect(conn, to: "/login")
      end
    else
      # No token found, redirect to login
      redirect(conn, to: "/login")
    end
  end

  def install(conn, _) do
    Tpn.Repo.insert(%Tpn.Accounts.Administrator{
      name: "Jawad",
      login_id: "jawad",
      hashed_password: Pbkdf2.hash_pwd_salt("password")
    })

    render(conn, :home, layout: false)
  end

  defp get_remember_me_cookie(conn) do
    conn = fetch_cookies(conn, signed: ["_tpn_web_user_remember_me"])
    conn.cookies["_tpn_web_user_remember_me"]
  end
end
