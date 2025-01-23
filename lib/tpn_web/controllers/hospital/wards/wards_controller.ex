defmodule TpnWeb.WardsController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Hospital.{Wards, Ward}
  alias TpnWeb.Helpers.ClientEvents
  alias TpnWeb.Helpers.Networks

  def index(conn, params) do
    with {:ok, {records, meta}} <- Wards.list_wards(params, conn) do
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
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"ward" => params}) do
    params = Networks.params_assign_networks(conn, params)

    case Wards.create_ward(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> Networks.assign_networks()
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> Networks.assign_networks()
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Wards.get_ward!(id)
    changeset = Wards.change_ward(record)

    conn
    |> Networks.assign_networks(record.local_health_network_id, record.facility_id)
    |> render(:edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ward" => params}) do
    record = Wards.get_ward!(id)

    params = Networks.params_assign_networks(conn, params)

    case Wards.update_ward(record, params) do
      {:ok, record} ->
        _changeset = Wards.change_ward(record)

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
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Wards.get_ward!(id)
    {:ok, _ward} = Wards.delete_ward(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    Wards.change_ward(%Ward{})
  end
end
