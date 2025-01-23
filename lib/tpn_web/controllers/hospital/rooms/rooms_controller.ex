defmodule TpnWeb.RoomsController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Hospital.{Rooms, Room}
  alias TpnWeb.Helpers.ClientEvents
  alias TpnWeb.Helpers.Networks

  def index(conn, params) do
    with {:ok, {records, meta}} <- Rooms.list_rooms(params, conn) do
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
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"room" => params}) do
    params = Networks.params_assign_networks(conn, params)

    case Rooms.create_room(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> Networks.assign_networks()
        |> assign(:wards, [])
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> Networks.assign_networks()
        |> assign(:wards, [])
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Rooms.get_room!(id)
    changeset = Rooms.change_room(record)

    conn
    |> Networks.assign_networks(record.local_health_network_id, record.facility_id)
    |> assign(:wards, Networks.get_wards(record))
    |> render(:edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "room" => params}) do
    record = Rooms.get_room!(id)

    params = Networks.params_assign_networks(conn, params)

    case Rooms.update_room(record, params) do
      {:ok, record} ->
        _changeset = Rooms.change_room(record)

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
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Rooms.get_room!(id)
    {:ok, _room} = Rooms.delete_room(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    Rooms.change_room(%Room{})
  end
end
