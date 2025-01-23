defmodule Tpn.Accounts.Networks.Campus do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name, :code]
  @sortable_fields [:name, :code]

  schema "campuses" do
    field :name, :string
    field :code, :string

    belongs_to :facility, Tpn.Accounts.Networks.Facility
    timestamps(type: :utc_datetime)
  end

  def changeset(campus, attrs) do
    campus
    |> cast(attrs, [:name, :code, :facility_id])
    |> validate_required([:name, :code, :facility_id])
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
