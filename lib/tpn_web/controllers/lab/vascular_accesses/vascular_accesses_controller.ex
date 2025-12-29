defmodule TpnWeb.VascularAccessesController do
  use TpnWeb, :controller

  alias Tpn.VascularAccess
  alias Tpn.VascularAccesses
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- VascularAccesses.list_vascular_accesses(params) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def new(conn, _params) do
    render(conn, :new, changeset: new_change())
  end

  def create(conn, %{"vascular_access" => params}) do
    params = Networks.params_assign_user(conn, params)

    case VascularAccesses.create_vascular_access(params) do
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
    record = VascularAccesses.get_vascular_access!(id)
    changeset = VascularAccesses.change_vascular_access(record)
    render(conn, :edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "vascular_access" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = VascularAccesses.get_vascular_access!(id)

    case VascularAccesses.update_vascular_access(record, params) do
      {:ok, _} ->
        conn
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "",
            "success",
            "Updated successfully."
          )
        )
        |> send_resp(204, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = VascularAccesses.get_vascular_access!(id)

    {:ok, _} = VascularAccesses.delete_vascular_access(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change do
    VascularAccesses.change_vascular_access(%VascularAccess{})
  end
end
