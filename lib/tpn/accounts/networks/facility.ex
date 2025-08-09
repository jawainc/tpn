defmodule Tpn.Accounts.Networks.Facility do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name, :code]
  @sortable_fields [:name, :code]

  schema "facilities" do
    field :name, :string
    field :code, :string

    belongs_to :local_health_network, Tpn.Accounts.Networks.LocalHealthNetwork
    timestamps(type: :utc_datetime)
  end

  def changeset(facility, attrs) do
    facility
    |> cast(attrs, [:name, :code, :local_health_network_id])
    |> validate_required([:name, :code, :local_health_network_id])
    |> unique_constraint([:name, :code], name: :facilities_name_code_index)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
