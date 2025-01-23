defmodule Tpn.UnitTypeUnit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "unit_type_units" do
    belongs_to :unit_type, Tpn.UnitType
    belongs_to :unit, Tpn.Unit
  end

  def changeset(unit_type_unit, params \\ %{}) do
    unit_type_unit
    |> cast(params, [:unit_id, :unit_type_id])
    |> validate_required([:unit_id, :unit_type_id])
  end
end