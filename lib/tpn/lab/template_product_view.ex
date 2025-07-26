defmodule Tpn.TemplateProductView do
  use Ecto.Schema

  @derive {Jason.Encoder, except: [:__struct__, :__meta__]}

  @filterable_fields [
    :template_name,
    :class_name,
    :formulary_name,
    :filling_method_name,
    :user_name
  ]

  @sortable_fields [
    :template_name,
    :class_name,
    :formulary_name,
    :filling_method_name,
    :user_name
  ]

  schema "template_products_view" do
    field :position, :integer
    field :template_id, :integer
    field :dose, :decimal
    field :additional_dose, :decimal
    field :additional_dose_allowed, :boolean
    field :max_allowed_limit, :decimal
    field :substance_locked_on_order, :boolean
    field :dose_unit, :string
    field :additional_dose_unit, :string
    field :max_allowed_unit, :string
    field :template_name, :string
    field :filling_method_name, :string
    field :filling_method_id, :integer
    field :user_name, :string
    field :formulary_name, :string
    field :formulary_id, :integer
    field :class_name, :string
    field :class_id, :integer
    field :inserted_at, :utc_datetime
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
