defmodule TpnWeb.Hospital.Components.PatientDetailsComponent do
  @moduledoc """
  module for defining patient components
  """
  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents
  import TpnWeb.IconComponents

  embed_templates "patient_details_component_html/*"

  @url "/patients/dashboard"

  @doc """
    defines the patient details component
  """
  attr :patient, :map, required: true
  attr :admission_number, :string, default: nil
  attr :admitted, :boolean, default: false
  attr :age, :string, required: false
  attr :can_be_discharged, :boolean, default: false
  def patient_details(assigns)

  def get_p_url, do: @url

  def format_lines(nil), do: ""

  def format_lines(string) do
    String.replace(string, "\n", "<br>")
  end
end
