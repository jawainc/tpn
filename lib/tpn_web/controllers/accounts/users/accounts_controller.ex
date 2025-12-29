defmodule TpnWeb.AccountsController do
  use TpnWeb, :controller
  import Ecto.Query, warn: false
  alias Tpn.Repo

  alias Tpn.Accounts.{Users, User}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {users, meta}} <- Users.list_users(params) do
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
    |> assign(:roles, get_roles())
    |> assign(:lhns, get_lhns())
    |> assign(:facilities, [])
    |> assign(:campuses, [])
    |> assign(:changeset, new_change())
    |> render(:new)
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
        |> assign(:roles, get_roles())
        |> assign(:lhns, get_lhns())
        |> assign(:facilities, [])
        |> assign(:campuses, [])
        |> assign(:changeset, new_change())
        |> render(:new)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:roles, get_roles())
        |> assign(:lhns, get_lhns())
        |> assign(:facilities, [])
        |> assign(:campuses, [])
        |> assign(:changeset, changeset)
        |> render(:new)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = Users.change_user(user)

    conn
    |> assign(:roles, get_roles())
    |> assign(:lhns, get_lhns())
    |> assign(:facilities, get_facilities(user.local_health_network_id))
    |> assign(:campuses, get_campuses(user.facility_id))
    |> assign(:changeset, changeset)
    |> assign(:user, user)
    |> render(:edit)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)

    case Users.update_user(user, params) do
      {:ok, user} ->
        changeset = Users.change_user(user)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> assign(:roles, get_roles())
        |> assign(:lhns, get_lhns())
        |> assign(:facilities, get_facilities(user.local_health_network_id))
        |> assign(:campuses, get_campuses(user.facility_id))
        |> assign(:changeset, changeset)
        |> assign(:user, user)
        |> render(:edit)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:roles, get_roles())
        |> assign(:lhns, get_lhns())
        |> assign(:facilities, get_facilities(user.local_health_network_id))
        |> assign(:campuses, get_campuses(user.facility_id))
        |> assign(:changeset, changeset)
        |> assign(:user, user)
        |> render(:edit)
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

  def show(conn, %{"id" => id}) do
    user = Users.get_user_role!(id)
    render(conn, :show, user: user)
  end

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    {:ok, _user} = Users.delete_user(user)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(200, "")
  end

  defp new_change() do
    Users.change_user(%User{})
  end

  defp get_roles() do
    Repo.all(Tpn.Accounts.Role, order_by: [asc: :name])
    |> Enum.map(fn x -> ["#{x.name}": x.id] end)
    |> List.flatten()
  end

  defp get_lhns() do
    Tpn.Accounts.Networks.LocalHealthNetwork
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp get_facilities(nil), do: []

  defp get_facilities(lhn_id) do
    Tpn.Accounts.Networks.Facility
    |> where([f], f.local_health_network_id == ^lhn_id)
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp get_campuses(nil), do: []

  defp get_campuses(facility_id) do
    Tpn.Accounts.Networks.Campus
    |> where([c], c.facility_id == ^facility_id)
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end
end
