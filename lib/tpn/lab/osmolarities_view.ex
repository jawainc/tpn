defmodule Tpn.Lab.OsmolaritiesView do
  use Ecto.Schema

  @filterable_fields [
    :name,
    :unit,
    :vascular_access,
    :patient_type,
    :user_name
  ]
  @sortable_fields [
    :name,
    :unit,
    :vascular_access,
    :patient_type,
    :user_name
  ]

  schema "osmolarities_view" do
    field :name, :string
    field :unit, :string
    field :vascular_access, :string
    field :patient_type, :string
    field :user_name, :string
    field :inserted_at, :utc_datetime
    field :unit_id, :integer
    field :vascular_access_id, :integer
    field :patient_type_id, :integer
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
