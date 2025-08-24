defmodule Tpn.FormularyView do
  use Ecto.Schema

  @derive {Jason.Encoder, except: [:__struct__, :__meta__]}

  @filterable_fields [
    :name,
    :code,
    :user_name,
    :solution_type_name,
    :class_name
  ]

  @sortable_fields [
    :name,
    :code,
    :solution_type_name,
    :user_name,
    :class_name
  ]

  schema "formularies_view" do
    field :name, :string
    field :label_friendly_name, :string
    field :code, :string
    field :is_enteral, :boolean
    field :concentration, :decimal
    field :calories, :decimal
    field :cost_per_container, :decimal
    field :container_size, :decimal
    field :print_on_label, :boolean
    field :include_in_overfill, :boolean
    field :universal_fluid, :boolean
    field :class_id, :integer
    field :concentration_unit_id, :integer
    field :calories_unit_id, :integer
    field :uom_unit_id, :integer
    field :solution_type_id, :integer
    field :user_id, :integer
    field :inserted_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :class_name, :string
    field :concentration_unit_name, :string
    field :calories_unit_name, :string
    field :uom_unit_name, :string
    field :solution_type_name, :string
    field :user_name, :string
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
