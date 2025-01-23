defmodule TpnWeb.Administrator.RolesController do
  use TpnWeb, :controller

  alias Tpn.Accounts.{Roles, Role}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {records, meta}} <- Roles.list_roles(params) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def new(conn, _params) do
    conn
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"role" => params}) do
    case Roles.create_role(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    role = Roles.get_role!(id)
    changeset = Roles.change_role(role)

    conn
    |> render(:edit, record: role, changeset: changeset)
  end

  def update(conn, %{"id" => id, "role" => params}) do
    record = Roles.get_role!(id)

    case Roles.update_role(record, params) do
      {:ok, record} ->
        changeset = Roles.change_role(record)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:edit, record: record, changeset: changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Roles.get_role!(id)
    {:ok, _role} = Roles.delete_role(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(200, "")
  end

  defp new_change() do
    Roles.change_role(%Role{})
  end
end
