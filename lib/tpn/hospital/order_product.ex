defmodule Tpn.OrderProduct do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  OrderProduct schema for managing products within TPN orders.

  This schema represents the many-to-many relationship between orders and products,
  storing specific product configurations and calculations for each order.
  """

  schema "order_products" do
    # Foreign keys
    belongs_to :order, Tpn.Order
    belongs_to :formulary, Tpn.Formulary

    # Product configuration
    field :position, :integer
    field :class_id, :integer
    field :class_name, :string
    field :dose, :decimal
    field :dose_unit, :string
    field :filling_method_id, :integer
    field :filling_method_name, :string
    field :volume, :decimal
    field :fill_volume, :decimal
    field :additional_dose, :decimal
    field :additional_dose_unit, :string
    field :max_allowed_limit, :decimal
    field :max_allowed_unit, :string
    field :substance_locked_on_order, :boolean, default: false

    # Calculation fields
    field :osmolarity_contribution, :decimal
    field :electrolyte_contributions, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for order products.
  """
  def changeset(order_product, attrs) do
    order_product
    |> cast(attrs, [
      :order_id,
      :formulary_id,
      :position,
      :class_id,
      :class_name,
      :dose,
      :dose_unit,
      :filling_method_id,
      :filling_method_name,
      :volume,
      :fill_volume,
      :additional_dose,
      :additional_dose_unit,
      :max_allowed_limit,
      :max_allowed_unit,
      :substance_locked_on_order,
      :osmolarity_contribution,
      :electrolyte_contributions
    ])
    |> validate_required([
      :order_id,
      :formulary_id,
      :position,
      :class_id,
      :class_name
    ])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_number(:dose, greater_than_or_equal_to: 0)
    |> validate_number(:volume, greater_than_or_equal_to: 0)
    |> validate_number(:fill_volume, greater_than_or_equal_to: 0)
    |> validate_number(:additional_dose, greater_than_or_equal_to: 0)
    |> validate_number(:max_allowed_limit, greater_than_or_equal_to: 0)
    |> validate_number(:osmolarity_contribution, greater_than_or_equal_to: 0)
  end

  @doc """
  Creates a changeset for bulk insertion of order products.
  """
  def bulk_changeset(order_products, attrs_list) do
    order_products
    |> cast(attrs_list, [
      :order_id,
      :formulary_id,
      :position,
      :class_id,
      :class_name,
      :dose,
      :dose_unit,
      :filling_method_id,
      :filling_method_name,
      :volume,
      :fill_volume,
      :additional_dose,
      :additional_dose_unit,
      :max_allowed_limit,
      :max_allowed_unit,
      :substance_locked_on_order,
      :osmolarity_contribution,
      :electrolyte_contributions
    ])
  end
end
