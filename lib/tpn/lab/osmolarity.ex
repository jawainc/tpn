defmodule Tpn.Lab.Osmolarity do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "osmolarities" do
    field :name, :string

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
      :unit_id,
      :vascular_access_id,
      :patient_type_id,
      :user_id
    ])
    |> validate_required([
      :name,
      :unit_id,
      :vascular_access_id,
      :patient_type_id,
      :user_id
    ])
    |> unique_constraint(:name)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
