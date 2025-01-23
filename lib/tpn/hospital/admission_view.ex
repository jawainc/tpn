defmodule Tpn.AdmissionView do
  use Ecto.Schema

  @filterable_fields [
    :admission_no,
    :discharged,
    :discharged_at,
    :age,
    :patient_type,
    :local_health_network,
    :facility,
    :campus,
    :ward,
    :room,
    :bed,
    :user,
    :mrn
  ]

  @sortable_fields [
    :admission_no,
    :discharged,
    :discharged_at,
    :age,
    :patient_type,
    :local_health_network,
    :facility,
    :campus,
    :ward,
    :room,
    :bed,
    :user,
    :mrn
  ]

  schema "admissions_view" do
    field :admission_no, :string
    field :discharged, :boolean
    field :discharged_at, :naive_datetime
    field :age, :string
    field :notes, :string
    field :patient_weight, :decimal
    field :patient_height, :decimal

    field :weight_unit, :string
    field :height_unit, :string
    field :first_name, :string
    field :last_name, :string
    field :patient_type, :string
    field :local_health_network, :string
    field :facility, :string
    field :campus, :string
    field :ward, :string
    field :room, :string
    field :bed, :string
    field :user_name, :string
    field :mrn, :string

    field :inserted_at, :utc_datetime
    field :patient_id, :integer
    field :patient_type_id, :integer
    field :local_health_network_id, :integer
    field :facility_id, :integer
    field :campus_id, :integer
    field :ward_id, :integer
    field :room_id, :integer
    field :bed_id, :integer
    field :user_id, :integer
  end
end
