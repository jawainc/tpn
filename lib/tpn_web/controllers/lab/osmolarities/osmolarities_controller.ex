defmodule TpnWeb.OsmolaritiesController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Lab.{Osmolarities, Osmolarity}
  alias Tpn.Units
  alias Tpn.PatientTypes
  alias Tpn.VascularAccesses
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- Osmolarities.list_osmolarities(params, conn) do
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
    |> assign(:units, Units.units_for_select())
    |> assign(:patient_types, PatientTypes.patient_types_for_select())
    |> assign(:vascular_accesses, VascularAccesses.vascular_accesses_for_select())
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"osmolarity" => params}) do
    params = Networks.params_assign_user(conn, params)

    case Osmolarities.create_osmolarity(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> assign(:units, Units.units_for_select())
        |> assign(:patient_types, PatientTypes.patient_types_for_select())
        |> assign(:vascular_accesses, VascularAccesses.vascular_accesses_for_select())
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:units, Units.units_for_select())
        |> assign(:patient_types, PatientTypes.patient_types_for_select())
        |> assign(:vascular_accesses, VascularAccesses.vascular_accesses_for_select())
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Osmolarities.get_osmolarity!(id)
    changeset = Osmolarities.change_osmolarity(record)

    conn
    |> assign(:units, Units.units_for_select())
    |> assign(:patient_types, PatientTypes.patient_types_for_select())
    |> assign(:vascular_accesses, VascularAccesses.vascular_accesses_for_select())
    |> render(:edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "osmolarity" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = Osmolarities.get_osmolarity!(id)

    case Osmolarities.update_osmolarity(record, params) do
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
        |> assign(:units, Units.units_for_select())
        |> assign(:patient_types, PatientTypes.patient_types_for_select())
        |> assign(:vascular_accesses, VascularAccesses.vascular_accesses_for_select())
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Osmolarities.get_osmolarity!(id)
    {:ok, _bed} = Osmolarities.delete_osmolarity(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change do
    %Osmolarity{}
    |> Osmolarity.changeset(%{})
  end
end
