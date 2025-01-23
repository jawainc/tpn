defmodule Tpn.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:unit]
  @sortable_fields [:unit]

  schema "units" do
    field :unit, :string
    belongs_to :user, Tpn.Accounts.User
    many_to_many :types, Tpn.UnitType, join_through: Tpn.UnitTypeUnit

    timestamps(type: :utc_datetime)
  end

  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:unit, :user_id])
    |> validate_required([:unit, :user_id])
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end

end