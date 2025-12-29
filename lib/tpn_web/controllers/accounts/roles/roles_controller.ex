defmodule TpnWeb.RolesController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Repo
  alias Tpn.Accounts.{Roles, Role, RoleRight}
  alias Tpn.Accounts.Context.Context
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

  def rights(conn, %{"id" => id}) do
    contexts = Repo.all(Context)
    rights = RoleRight |> where(role_id: ^id) |> Repo.all()
    role = Repo.get!(Role, id)

    conn
    |> render(:rights, role: role, rights: rights, contexts: contexts)
  end

  def update_rights(conn, %{"rights" => rights}) do
    Repo.insert!(
      %RoleRight{
        create: Map.has_key?(rights, "create"),
        delete: Map.has_key?(rights, "delete"),
        read: Map.has_key?(rights, "delete"),
        role_id: String.to_integer(rights["role_id"]),
        context_id: String.to_integer(rights["context_id"]),
        update: Map.has_key?(rights, "update")
      },
      on_conflict: [
        set: [
          create: Map.has_key?(rights, "create"),
          delete: Map.has_key?(rights, "delete"),
          read: Map.has_key?(rights, "read"),
          update: Map.has_key?(rights, "update")
        ]
      ],
      conflict_target: [:role_id, :context_id]
    )

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("", "success", "Updated successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    Roles.change_role(%Role{})
  end
end
