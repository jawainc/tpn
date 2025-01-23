defmodule Tpn.Admission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admissions" do
    field :admission_no, :string
    field :discharged, :boolean, default: false
    field :discharged_at, :naive_datetime
    field :age, :string
    field :notes, :string
    field :patient_weight, :decimal
    field :patient_height, :decimal

    belongs_to :weight_unit, Tpn.Unit
    belongs_to :height_unit, Tpn.Unit
    belongs_to :patient, Tpn.Patient
    belongs_to :patient_type, Tpn.PatientType
    belongs_to :local_health_network, Tpn.Accounts.Networks.LocalHealthNetwork
    belongs_to :facility, Tpn.Accounts.Networks.Facility
    belongs_to :campus, Tpn.Accounts.Networks.Campus
    belongs_to :ward, Tpn.Hospital.Ward
    belongs_to :room, Tpn.Hospital.Room
    belongs_to :bed, Tpn.Hospital.Bed
    belongs_to :user, Tpn.Accounts.User

    has_one :mrn, Tpn.Hospital.PatientMrn

    timestamps(type: :utc_datetime)
  end

  def changeset(admission, attrs) do
    admission
    |> cast(attrs, [
      :admission_no,
      :discharged,
      :discharged_at,
      :age,
      :notes,
      :patient_weight,
      :patient_height,
      :weight_unit_id,
      :height_unit_id,
      :patient_id,
      :patient_type_id,
      :local_health_network_id,
      :facility_id,
      :campus_id,
      :ward_id,
      :room_id,
      :bed_id,
      :user_id
    ])
  end
end
