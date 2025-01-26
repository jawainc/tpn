defmodule TpnWeb.Hospital.AdmissionsController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false
  alias Tpn.{Admissions, Admission, Patients, Units, Settings, PatientTypes}
  alias Tpn.Hospital.Wards
  alias TpnWeb.Helpers.{ClientEvents, Networks, PatientHelper}

  @weight_unit_type "patient_weight_unit_type"
  @height_unit_type "patient_height_unit_type"

  def new(conn, %{"id" => id}) do
    age = PatientHelper.calc_age(id)
    admission_no = PatientHelper.generate_admission_number()

    current_user = conn.assigns[:current_user]
    mrn = get_mrn(id, current_user)
    wards = get_wards(current_user)
    has_campus = has_campus?(current_user)

    conn
    |> assign(:mrn, mrn)
    |> assign(:age, age)
    |> assign(:patient_id, id)
    |> assign(:admission_no, admission_no)
    |> assign(:has_campus, has_campus)
    |> assign(:wards, wards)
    |> assign(:rooms, [])
    |> assign(:beds, [])
    |> set_assigns()
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"admission" => admission_params}) do
    current_user = conn.assigns[:current_user]
    admission_params = Map.put(admission_params, "user_id", current_user.id)

    case Admissions.create_admission(admission_params) do
      {:ok, admission} ->
        conn
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "reloadPatientAdmissionTable",
            "success",
            "Created successfully."
          )
        )
        |> send_resp(204, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        wards = get_wards(current_user)
        has_campus = has_campus?(current_user)

        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:has_campus, has_campus)
        |> assign(:wards, wards)
        |> assign(:rooms, [])
        |> assign(:beds, [])
        |> assign(:age, admission_params["age"])
        |> assign(:patient_id, admission_params["patient_id"])
        |> assign(:admission_no, admission_params["admission_no"])
        |> set_assigns()
        |> render(:new, changeset: changeset)
    end
  end

  def new_change do
    Admissions.change_admission(%Admission{})
  end

  defp get_mrn(_, %{campus_id: nil}), do: nil

  defp get_mrn(patient_id, %{campus_id: campus_id}) do
    admision_mrn = Admissions.get_mrn(patient_id, campus_id)

    if admision_mrn do
      admision_mrn.mrn
    else
      nil
    end
  end

  defp get_wards(%{campus_id: nil}), do: []

  defp get_wards(%{campus_id: campus_id}) do
    Wards.get_wards_for_select_by_campus_id(campus_id)
  end

  defp has_campus?(%{campus_id: nil}), do: false
  defp has_campus?(%{campus_id: _}), do: true

  defp set_assigns(conn) do
    settings = get_settings()
    weight_units = Units.units_by_type_for_select(settings[@weight_unit_type])
    height_units = Units.units_by_type_for_select(settings[@height_unit_type])

    conn
    |> Networks.assign_networks()
    |> assign(:patient_types, PatientTypes.patient_types_for_select())
    |> assign(:weight_units, weight_units)
    |> assign(:height_units, height_units)
  end

  defp get_settings() do
    Settings.get_settings()
    |> Enum.map(&{&1.key, &1.value})
    |> Enum.into(%{})
  end
end
