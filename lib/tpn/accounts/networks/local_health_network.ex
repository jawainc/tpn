defmodule Tpn.Accounts.Networks.LocalHealthNetwork do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name, :code]
  @sortable_fields [:name, :code]

  schema "local_health_networks" do
    field :name, :string
    field :code, :string

    has_many :facilities, Tpn.Accounts.Networks.Facility
    has_many :campuses, through: [:facilities, :campuses]

    timestamps(type: :utc_datetime)
  end

  def changeset(local_health_network, attrs) do
    local_health_network
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
