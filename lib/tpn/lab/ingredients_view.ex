defmodule Tpn.Lab.IngredientsView do
  use Ecto.Schema

  @filterable_fields [
    :name,
    :unit_type,
    :user_name
  ]

  @sortable_fields [
    :name,
    :unit_type,
    :user_name
  ]

  schema "ingredients_view" do
    field :name, :string
    field :unit_type, :string
    field :user_name, :string
    field :inserted_at, :utc_datetime
    field :print_on_label, :boolean
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
