defmodule TpnWeb.Hospital.PatientDashboardController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false
  alias Tpn.{Patients, Patient}
  alias TpnWeb.Helpers.{ClientEvents, Networks, PatientHelper}

  def index(conn, params) do
    with {:ok, {records, meta}} <- Patients.list_patients(params, conn) do
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
    |> assign(:genders, Patients.get_genders())
    |> render(:new, changeset: new_change())
  end

  def edit(conn, %{"id" => id}) do
    record = Patients.get_patient_view!(id)
    changeset = Patients.change_patient(Patients.get_patient!(id))

    conn
    |> Networks.assign_networks(record.local_health_network_id, record.facility_id)
    |> assign(:genders, Patients.get_genders())
    |> assign(:record, record)
    |> render(:edit, changeset: changeset)
  end

  def show(conn, %{"id" => id}) do
    conn
    |> show_assigns(id)
  end

  def new_change do
    Patients.change_patient(%Patient{})
  end

  def create(conn, %{"patient" => patient_params}) do
    params =
      patient_params
      |> set_networks(conn)
      |> set_dob(false)
      |> Map.put("tpn_id", PatientHelper.generate_tpn_number())

    case Patients.create_patient(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> Networks.assign_networks()
        |> assign(:genders, Patients.get_genders())
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> Networks.assign_networks()
        |> assign(:genders, Patients.get_genders())
        |> render(:new, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "patient" => patient_params}) do
    record = Patients.get_patient!(id)

    params =
      patient_params
      |> set_networks(conn)
      |> set_dob()

    case Patients.update_patient(record, params) do
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
        record = Patients.get_patient_view!(id)

        conn
        |> Networks.assign_networks(record.local_health_network_id, record.facility_id)
        |> assign(:genders, Patients.get_genders())
        |> assign(:record, record)
        |> render(:edit, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Patients.get_patient!(id)
    params = %{"cancelled" => true}

    Patients.delete_patient(record, params)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Cancelled successfully.")
    )
    |> send_resp(204, "")
  end

  defp show_assigns(conn, id) do
    patient = Patients.get_patient_view!(id)
    age = PatientHelper.calc_age(id)

    can_be_discharged =
      PatientHelper.can_be_discharged?(conn.assigns, id)

    conn
    |> assign(:can_be_discharged, can_be_discharged)
    |> assign(:age, age)
    |> assign(:patient, patient)
    |> assign(:admissions, Patients.get_admissions(id))
    |> render(:show)
  end

  defp set_dob(params, edit \\ true) do
    case params["dob"] do
      nil ->
        if edit, do: params, else: Map.put(params, "dob", "")

      "" ->
        if edit, do: params, else: Map.put(params, "dob", "")

      date ->
        dob =
          if edit do
            date
          else
            date
            |> Timex.parse!("{YYYY}-{M}-{D}")
            |> Timex.to_date()
          end

        Map.put(params, "dob", dob)
    end
  end

  defp set_networks(params, conn) do
    case params["local_health_network_id"] do
      nil -> params
      _ -> Networks.params_assign_networks(conn, params)
    end
  end
end
