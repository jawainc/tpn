defmodule TpnWeb.PageController do
  use TpnWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def install(conn, _) do
    Tpn.Repo.insert(%Tpn.Accounts.Administrator{
      name: "Jawad",
      login_id: "jawad",
      hashed_password: Pbkdf2.hash_pwd_salt("password")
    })

    render(conn, :home, layout: false)
  end
end
