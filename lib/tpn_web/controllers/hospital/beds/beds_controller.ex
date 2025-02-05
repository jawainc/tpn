defmodule TpnWeb.BedsController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Hospital.Room
  alias Tpn.Hospital.{Beds, Bed}
  alias TpnWeb.Helpers.ClientEvents
  alias TpnWeb.Helpers.Networks

  def index(conn, params) do
    with {:ok, {records, meta}} <- Beds.list_beds(params, conn) do
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
    |> Networks.assign_networks()
    |> assign(:wards, [])
    |> assign(:rooms, [])
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"bed" => params}) do
    params = Networks.params_assign_networks(conn, params)

    case Beds.create_bed(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> Networks.assign_networks()
        |> assign(:wards, [])
        |> assign(:rooms, [])
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> Networks.assign_networks()
        |> assign(:wards, [])
        |> assign(:rooms, [])
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Beds.get_bed!(id)
    changeset = Beds.change_bed(record)

    conn
    |> Networks.assign_networks(record.local_health_network_id, record.facility_id)
    |> assign(:wards, Networks.get_wards(record))
    |> assign(:rooms, get_rooms(record.ward_id))
    |> render(:edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "bed" => params}) do
    record = Beds.get_bed!(id)

    params = Networks.params_assign_networks(conn, params)

    case Beds.update_bed(record, params) do
      {:ok, record} ->
        _changeset = Beds.change_bed(record)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "reloadDataTable",
            "success",
            "Updated successfully."
          )
        )
        |> send_resp(204, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> Networks.assign_networks()
        |> assign(:wards, Networks.get_wards(record))
        |> assign(:rooms, get_rooms(record.ward_id))
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Beds.get_bed!(id)
    {:ok, _bed} = Beds.delete_bed(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    Beds.change_bed(%Bed{})
  end

  defp get_rooms(nil), do: []

  defp get_rooms(id) do
    Room
    |> where([r], r.ward_id == ^id)
    |> order_by(asc: :name)
    |> Tpn.Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end
end
