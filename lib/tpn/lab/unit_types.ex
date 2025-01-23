defmodule Tpn.UnitTypes do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.UnitType
  alias Tpn.Helpers.PaginationHelper

  def unit_types() do
    Repo.all(UnitType, order_by: [asc: :name])
  end

  def list_unit_types(params) do
    unit_types =
      from(a in UnitType)
      |> PaginationHelper.build_query_params(UnitType, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(a in UnitType)
      |> PaginationHelper.get_paging_meta(params, UnitType)

    {:ok, {unit_types, meta}}
  end

  def unit_types_for_select do
    Repo.all(UnitType)
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_unit_type(params) do
    %UnitType{}
    |> UnitType.changeset(params)
    |> Repo.insert()
  end

  def get_unit_type!(id) do
    Repo.get!(UnitType, id)
  end

  def change_unit_type(unit_type) do
    UnitType.changeset(unit_type, %{})
  end

  def update_unit_type(unit_type, params) do
    unit_type
    |> UnitType.changeset(params)
    |> Repo.update()
  end

  def delete_unit_type(unit_type) do
    from(utu in Tpn.UnitTypeUnit, where: utu.unit_type_id == ^unit_type.id) |> Repo.delete_all()
    Repo.delete(unit_type)
  end
end
