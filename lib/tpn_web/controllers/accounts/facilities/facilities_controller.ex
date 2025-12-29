defmodule TpnWeb.FacilitiesController do
  use TpnWeb, :controller
  import Ecto.Query, warn: false
  alias Tpn.Repo

  alias Tpn.Accounts.Networks.{Facility, Facilities}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {records, meta}} <- Facilities.list_facilities(params) do
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
    |> render(:new, changeset: new_change(), lhns: get_lhns())
  end

  def create(conn, %{"facility" => params}) do
    case Facilities.create_facility(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> render(:new, changeset: new_change(), lhns: get_lhns())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:new, changeset: changeset, lhns: get_lhns())
    end
  end

  def edit(conn, %{"id" => id}) do
    local_health_network = Facilities.get_facility!(id)
    changeset = Facilities.change_facility(local_health_network)

    conn
    |> render(:edit, record: local_health_network, changeset: changeset, lhns: get_lhns())
  end

  def update(conn, %{"id" => id, "facility" => params}) do
    record = Facilities.get_facility!(id)

    case Facilities.update_facility(record, params) do
      {:ok, record} ->
        changeset = Facilities.change_facility(record)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> render(:edit, record: record, changeset: changeset, lhns: get_lhns())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, record: record, changeset: changeset, lhns: get_lhns())
    end
  end

  def delete(conn, %{"id" => id}) do
    local_health_network = Facilities.get_facility!(id)

    {:ok, _local_health_network} =
      Facilities.delete_facility(local_health_network)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(200, "")
  end

  defp new_change do
    Facilities.change_facility(%Facility{})
  end

  defp get_lhns do
    Tpn.Accounts.Networks.LocalHealthNetwork
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end
end
