defmodule Tpn.Hospital.RoomsView do
  use Ecto.Schema

  @filterable_fields [:name, :code, :ward, :local_health_network, :facility, :campus, :user_name]
  @sortable_fields [:name, :code, :ward, :local_health_network, :facility, :campus, :user_name]

  schema "rooms_view" do
    field :name, :string
    field :code, :string

    field :ward, :string
    field :local_health_network_id, :integer
    field :facility_id, :integer
    field :campus_id, :integer
    field :user_id, :integer
    field :local_health_network, :string
    field :facility, :string
    field :campus, :string
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
