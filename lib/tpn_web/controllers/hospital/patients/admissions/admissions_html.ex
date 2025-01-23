defmodule TpnWeb.Hospital.AdmissionsHTML do
  use TpnWeb, :html

  @url "/patients/admissions"
  embed_templates "admissions_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  attr :is_admin, :boolean, default: false
  attr :can, :map, default: %{}
  attr :current_user, :map, default: %{}
  attr :lhns, :list, default: []
  attr :facilities, :list, default: []
  attr :campuses, :list, default: []
  attr :age, :string, default: ""
  attr :patient_id, :string, default: ""
  attr :admission_no, :string, default: ""
  attr :wards, :list, default: []
  attr :rooms, :list, default: []
  attr :beds, :list, default: []
  attr :patient_types, :list, default: []
  attr :weight_units, :list, default: []
  attr :height_units, :list, default: []
  def data_form(assigns)

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
end
