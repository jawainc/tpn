defmodule TpnWeb.UserAuth do
  use TpnWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Tpn.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_tpn_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_token_in_session(token, user.role.is_admin)
    |> maybe_write_remember_me_cookie(token, params)
    |> put_resp_header("hx-redirect", signed_in_path(conn))
    |> send_resp(204, "")
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn, context \\ "session") do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token, context)

    if live_socket_id = get_session(conn, :live_socket_id) do
      TpnWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> put_resp_header(
      "hx-redirect",
      if(context == "admin-session") do
        ~p"/administrator/login"
      else
        ~p"/login"
      end
    )
    |> send_resp(200, "")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, from_dash \\ false) do
    with {:ok, user_token, conn} <- ensure_user_token(conn),
         {:ok, user} <- user_token && Accounts.get_user_by_session_token(user_token) do
      access_level = user && get_access_level(conn, user.role_id)

      if !access_level do
        redirect_to_login(conn, from_dash)
      end

      can = gen_user_auth_can(access_level, conn)

      conn
      |> assign(:current_user, user)
      |> assign(:is_admin, is_admin?(conn))
      |> assign(:user_access_level, access_level)
      |> assign(:can, can)
    else
      _ ->
        redirect_to_login(conn, from_dash)
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {:ok, token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {:ok, token, put_token_in_session(conn, token, is_admin?(conn))}
      else
        {:error, nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _) do
    conn = fetch_current_user(conn)

    if conn.assigns[:current_user] do
      conn
    else
      redirect_to_login(conn, false)
    end
  end

  def require_authenticated_dash_user(conn, _) do
    conn = fetch_current_user(conn, true)

    if conn.assigns[:current_user] do
      conn
    else
      redirect_to_login(conn, true)
    end
  end

  def require_authenticated_admin(conn, _opts) do
    if conn.assigns[:is_admin] do
      conn
    else
      redirect_to_login(conn, true)
    end
  end

  defp put_token_in_session(conn, token, is_admin) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:is_admin, is_admin)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp signed_in_path(_conn), do: ~p"/dashboard"

  defp is_admin?(conn) do
    get_session(conn, :is_admin)
  end

  defp get_access_level(conn, role_id) do
    case is_admin?(conn) do
      true -> []
      _ -> TpnWeb.Auth.UserAccessLevel.generate_role_rights(role_id)
    end
  end

  defp gen_user_auth_can(access_level, conn) do
    case is_admin?(conn) do
      true ->
        %{read: true, create: true, update: true, delete: true}

      _ ->
        if conn.request_path == "/dashboard" || conn.request_path == "/dash" do
          %{read: true, create: false, update: false, delete: false}
        else
          found =
            Enum.find_value(access_level, fn level ->
              if String.starts_with?(conn.request_path, level.context), do: level
            end)

          if is_nil(found) do
            %{read: false, create: false, update: false, delete: false}
          else
            %{read: found.read, create: found.create, update: found.update, delete: found.delete}
          end
        end
    end
  end

  defp redirect_to_login(conn, false) do
    conn
    |> put_flash(:error, "You must log in to access this page.")
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/login")
    |> halt()
  end

  defp redirect_to_login(conn, true) do
    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> put_resp_header("hx-redirect", ~p"/login")
    |> send_resp(200, "")
  end
end
