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

    conn
    |> assign(:mrn, mrn)
    |> assign(:age, age)
    |> assign(:patient_id, id)
    |> assign(:admission_no, admission_no)
    |> assign(:wards, wards)
    |> assign(:rooms, [])
    |> assign(:beds, [])
    |> set_assigns()
    |> render(:new, changeset: new_change())
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
