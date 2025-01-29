defmodule Tpn.PatientMrn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_mrns" do
    field :mrn, :string

    belongs_to :patient, Tpn.Patient
    belongs_to :local_health_network, Tpn.Accounts.Networks.LocalHealthNetwork
    belongs_to :facility, Tpn.Accounts.Networks.Facility
    belongs_to :campus, Tpn.Accounts.Networks.Campus
    belongs_to :user, Tpn.Accounts.User

    timestamps()
  end

  def changeset(patient_mrn, attrs) do
    patient_mrn
    |> cast(attrs, [
      :mrn,
      :patient_id,
      :local_health_network_id,
      :facility_id,
      :campus_id,
      :user_id
    ])
    |> validate_required([
      :mrn,
      :patient_id,
      :local_health_network_id,
      :facility_id,
      :campus_id,
      :user_id
    ])
    |> unique_constraint(:mrn, name: :unique_mrn_per_campus)
  end
end
