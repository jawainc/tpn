defmodule TpnWeb.Administrator.AccountsController do
  use TpnWeb, :controller

  alias Tpn.Accounts.{Users, User}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {users, meta}} <- Users.list_users_for_admin(params) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: users)
    end
  end

  def new(conn, _params) do
    conn
    |> render(:new, changeset: new_change(), roles: get_roles())
  end

  def create(conn, %{"user" => params}) do
    case Users.create_user(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:new, changeset: new_change(), roles: get_roles())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:new, changeset: changeset, roles: get_roles())
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = Users.change_user(user)

    conn
    |> render(:edit, user: user, changeset: changeset, roles: get_roles())
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)

    case Users.update_user(user, params) do
      {:ok, user} ->
        changeset = Users.change_user(user)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:edit, user: user, changeset: changeset, roles: get_roles())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, user: user, changeset: changeset, roles: get_roles())
    end
  end

  def change_password(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = Users.change_password(user)

    conn
    |> render(:change_password, user: user, changeset: changeset)
  end

  def update_password(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)

    case Users.update_password(user, params) do
      {:ok, user} ->
        changeset = Users.change_password(user)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> render(:change_password, user: user, changeset: changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:change_password, user: user, changeset: changeset)
    end
  end

  defp new_change() do
    Users.change_user(%User{})
  end

  defp get_roles() do
    Tpn.Repo.all(Tpn.Accounts.Role, order_by: [asc: :name])
    |> Enum.map(fn x -> ["#{x.name}": x.id] end)
    |> List.flatten()
  end
end
