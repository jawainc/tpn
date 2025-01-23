defmodule TpnWeb.PatientTypesController do
  use TpnWeb, :controller

  alias Tpn.PatientType
  alias Tpn.PatientTypes
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- PatientTypes.list_patient_types(params) do
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

  def create(conn, %{"patient_type" => params}) do
    params = Networks.params_assign_user(conn, params)

    case PatientTypes.create_patient_type(params) do
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
    record = PatientTypes.get_patient_type!(id)
    changeset = PatientTypes.change_patient_type(record)
    render(conn, :edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "patient_type" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = PatientTypes.get_patient_type!(id)

    case PatientTypes.update_patient_type(record, params) do
      {:ok, _} ->
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
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = PatientTypes.get_patient_type!(id)

    {:ok, _} = PatientTypes.delete_patient_type(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    PatientTypes.change_patient_type(%PatientType{})
  end
end
