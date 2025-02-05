defmodule TpnWeb.Hospital.PatientDashboardHTML do
  use TpnWeb, :html
  import TpnWeb.Hospital.Components.PatientDetailsComponent
  import TpnWeb.Hospital.Components.PatientAdmissionsComponent

  @url "/patients/dashboard"
  embed_templates "patient_dashboard_html/*"

  def get_url, do: @url

  def netwrok_access(true, _, _), do: true

  def netwrok_access(false, "facility", user) do
    if is_nil(user.facility_id) do
      true
    else
      false
    end
  end

  def netwrok_access(false, "campus", user) do
    if is_nil(user.campus_id) do
      true
    else
      false
    end
  end

  def can_manage?(patient, %{local_health_network_id: id, facility_id: nil, campus_id: nil}) do
    patient.local_health_network_id == id
  end

  def can_manage?(patient, %{facility_id: id, campus_id: nil}) do
    patient.facility_id == id
  end

  def can_manage?(patient, %{campus_id: id}) do
    patient.campus_id == id
  end
end
