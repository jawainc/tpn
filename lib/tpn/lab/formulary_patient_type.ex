defmodule Tpn.FormularyPatientType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "formulary_patient_types" do
    belongs_to :formulary, Tpn.Formulary
    belongs_to :patient_type, Tpn.PatientType
  end

  def changeset(formulary_patient_type, params \\ %{}) do
    formulary_patient_type
    |> cast(params, [:formulary_id, :patient_type_id])
    |> validate_required([:formulary_id, :patient_type_id])
  end
end
