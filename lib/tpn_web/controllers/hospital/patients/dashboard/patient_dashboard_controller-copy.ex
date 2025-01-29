defmodule TpnWeb.Hospital.PatientDashboardControllerCC do
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

  def show(conn, %{"id" => id}) do
    conn
    |> show_assigns(id)
  end

  def new_change do
    Patients.change_patient(%Patient{})
  end

  def create(conn, %{"patient" => patient_params}) do
    dob = patient_params["dob"]
    # Convert the date of birth to a date, supplied date string is in format January 1, 2025
    con_dob =
      case dob do
        nil ->
          ""

        "" ->
          ""

        date ->
          date
          |> Timex.parse!("{Mfull} {D}, {YYYY}")
          |> Timex.to_date()
      end

    params =
      Networks.params_assign_networks(conn, patient_params)
      |> Map.put("dob", con_dob)
      |> Map.put("tpn_id", PatientHelper.generate_tpn_number())

    case Patients.create_patient(params) do
      {:ok, patient} ->
        conn
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "",
            "success",
            "Created successfully."
          )
        )
        |> show_assigns(patient.id)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> Networks.assign_networks()
        |> assign(:genders, Patients.get_genders())
        |> render(:new, changeset: changeset)
    end
  end

  defp show_assigns(conn, id) do
    patient = Patients.get_patient!(id)
    age = PatientHelper.calc_age(id)

    can_be_discharged =
      PatientHelper.can_be_discharged?(conn.assigns, id)

    IO.inspect("Can be discharged: #{can_be_discharged}")

    conn
    |> assign(:can_be_discharged, can_be_discharged)
    |> assign(:age, age)
    |> assign(:patient, patient)
    |> assign(:admissions, get_admissions(id))
    |> render(:show)
  end

  defp get_admissions(id) do
    Patients.get_admissions(id)
  end
end
