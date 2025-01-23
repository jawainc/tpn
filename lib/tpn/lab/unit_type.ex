defmodule Tpn.UnitType do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "unit_types" do
    field :name, :string
    belongs_to :user, Tpn.Accounts.User

    many_to_many :units, Tpn.Unit, join_through: Tpn.UnitTypeUnit

    timestamps(type: :utc_datetime)
  end

  def changeset(unit_type, attrs) do
    unit_type
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end