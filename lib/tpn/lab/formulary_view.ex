defmodule Tpn.FormularyView do
  use Ecto.Schema

  @filterable_fields [
    :name,
    :code,
    :user_name
  ]

  @sortable_fields [
    :name,
    :code,
    :user_name
  ]

  schema "formularies_view" do
    field :name, :string
    field :code, :string
    field :cost_per_container, :decimal
    field :container_size, :decimal
    field :print_on_label, :boolean
    field :user_name, :string
    field :inserted_at, :utc_datetime
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
