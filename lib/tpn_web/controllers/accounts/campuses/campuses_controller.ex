defmodule TpnWeb.CampusesController do
  use TpnWeb, :controller
  import Ecto.Query, warn: false
  alias Tpn.Repo

  alias Tpn.Accounts.Networks.{Campus, Campuses}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {records, meta}} <- Campuses.list_campuses(params) do
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
    |> render(:new, changeset: new_change(), facilities: get_facilities())
  end

  def create(conn, %{"campus" => params}) do
    case Campuses.create_campus(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> render(:new, changeset: new_change(), facilities: get_facilities())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:new, changeset: changeset, facilities: get_facilities())
    end
  end

  def edit(conn, %{"id" => id}) do
    local_health_network = Campuses.get_campus!(id)
    changeset = Campuses.change_campus(local_health_network)

    conn
    |> render(:edit,
      record: local_health_network,
      changeset: changeset,
      facilities: get_facilities()
    )
  end

  def update(conn, %{"id" => id, "campus" => params}) do
    record = Campuses.get_campus!(id)

    case Campuses.update_campus(record, params) do
      {:ok, record} ->
        changeset = Campuses.change_campus(record)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> render(:edit, record: record, changeset: changeset, facilities: get_facilities())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, record: record, changeset: changeset, facilities: get_facilities())
    end
  end

  def delete(conn, %{"id" => id}) do
    local_health_network = Campuses.get_campus!(id)

    {:ok, _local_health_network} =
      Campuses.delete_campus(local_health_network)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(200, "")
  end

  defp new_change do
    Campuses.change_campus(%Campus{})
  end

  defp get_facilities do
    Tpn.Accounts.Networks.Facility
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end
end
