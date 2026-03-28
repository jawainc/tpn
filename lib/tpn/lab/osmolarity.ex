defmodule Tpn.Lab.Osmolarity do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "osmolarities" do
    field :name, :string
    field :osmolarity, :decimal
    field :alert_type, :string

    belongs_to :unit, Tpn.Unit
    belongs_to :vascular_access, Tpn.VascularAccess
    belongs_to :patient_type, Tpn.PatientType
    belongs_to :user, Tpn.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(osmolarity, attrs) do
    osmolarity
    |> cast(attrs, [
      :name,
      :osmolarity,
      :alert_type,
      :unit_id,
      :vascular_access_id,
      :patient_type_id,
      :user_id
    ])
    |> validate_required([
      :name,
      :osmolarity,
      :alert_type,
      :unit_id,
      :vascular_access_id,
      :patient_type_id,
      :user_id
    ])
    |> validate_number(:osmolarity, greater_than_or_equal_to: 0)
    |> validate_inclusion(:alert_type, ["Soft", "Hard"])
    |> unique_constraint(:name)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
