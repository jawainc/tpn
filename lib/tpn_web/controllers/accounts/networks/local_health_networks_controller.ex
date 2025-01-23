defmodule TpnWeb.Networks.LocalHealthNetworksController do
  use TpnWeb, :controller

  alias Tpn.Accounts.Networks.{LocalHealthNetworks, LocalHealthNetwork}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {records, meta}} <- LocalHealthNetworks.list_local_health_networks(params) do
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

  def create(conn, %{"local_health_network" => params}) do
    case LocalHealthNetworks.create_local_health_network(params) do
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
    local_health_network = LocalHealthNetworks.get_local_health_network!(id)
    changeset = LocalHealthNetworks.change_local_health_network(local_health_network)

    conn
    |> render(:edit, record: local_health_network, changeset: changeset)
  end

  def update(conn, %{"id" => id, "local_health_network" => params}) do
    record = LocalHealthNetworks.get_local_health_network!(id)

    case LocalHealthNetworks.update_local_health_network(record, params) do
      {:ok, record} ->
        changeset = LocalHealthNetworks.change_local_health_network(record)

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
    local_health_network = LocalHealthNetworks.get_local_health_network!(id)

    {:ok, _local_health_network} =
      LocalHealthNetworks.delete_local_health_network(local_health_network)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(200, "")
  end

  defp new_change do
    LocalHealthNetworks.change_local_health_network(%LocalHealthNetwork{})
  end
end
