defmodule Tpn.TemplateView do
  use Ecto.Schema

  @filterable_fields [
    :name,
    :patient_type_name,
    :user_name,
    :fluid_unit
  ]

  @sortable_fields [
    :name,
    :patient_type_name,
    :user_name,
    :fluid_unit
  ]

  schema "templates_view" do
    field :name, :string
    field :bag_over_fill_volume, :decimal
    field :lipid_over_fill_volume, :decimal
    field :active, :boolean
    field :fluids, :decimal
    field :pre_mixed_standard, :boolean
    field :additional_substances_allowed, :boolean
    field :fluid_unit, :string
    field :patient_type_name, :string
    field :user_name, :string
    field :fluid_unit_id, :id
    field :patient_type_id, :id
    field :user_id, :id
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
