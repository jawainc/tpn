defmodule Tpn.Units do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Unit
  alias Tpn.UnitTypeUnit
  alias Tpn.Helpers.PaginationHelper
  alias Ecto.Multi

  def list_units(params, conn) do
    units =
      from(a in Unit)
      |> PaginationHelper.build_query_params(Unit, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(a in Unit)
      |> PaginationHelper.get_paging_meta(params, Unit)

    {:ok, {units, meta}}
  end

  def units_for_select do
    Repo.all(Unit)
    |> Enum.map(&{&1.unit, &1.id})
  end

  def units_by_type_for_select(type_id) do
    id = String.to_integer(type_id)

    Repo.all(from(u in Unit, join: utu in assoc(u, :types), where: utu.id == ^id))
    |> Enum.map(&{&1.unit, &1.id})
  end

  def create(%{"types" => types} = attrs \\ %{}) do
    unit_types =
      types
      |> String.split(",")
      |> parse_list()
      |> Enum.map(fn x -> String.to_integer(x) end)

    multi =
      Multi.new()
      |> Multi.insert(:unit, %Unit{} |> Unit.changeset(attrs))
      |> Multi.insert_all(:unit_type_unit, UnitTypeUnit, fn %{unit: unit} ->
        unit_types
        |> Enum.uniq()
        |> Enum.map(fn id ->
          %{
            unit_id: unit.id,
            unit_type_id: id
          }
        end)
      end)

    case Repo.transaction(multi) do
      {:ok, %{unit: unit} = _multi_result} ->
        {:ok, unit}

      {:error, changeset} ->
        {:error, changeset}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_unit!(id) do
    Repo.get!(Unit, id)
  end

  def get_unit_with_types!(id) do
    Repo.get!(Unit, id)
    |> Repo.preload(:types)
  end

  def change_unit(unit) do
    Unit.changeset(unit, %{})
  end

  def update(id, %{"types" => types} = attrs) do
    unit = get_unit!(id)

    unit_types =
      types
      |> String.split(",")
      |> parse_list()
      |> Enum.map(fn x -> String.to_integer(x) end)

    multi =
      Multi.new()
      |> Multi.update(:unit, unit |> Unit.changeset(attrs))
      |> Multi.delete_all(
        :unit_type_deleted,
        fn %{unit: unit} ->
          UnitTypeUnit
          |> where([unit_type], unit_type.unit_id == ^unit.id)
        end,
        skip: true
      )
      |> Multi.insert_all(:unit_type_unit, UnitTypeUnit, fn %{unit: unit} ->
        unit_types
        |> Enum.uniq()
        |> Enum.map(fn id ->
          %{
            unit_id: unit.id,
            unit_type_id: id
          }
        end)
      end)

    case Repo.transaction(multi) do
      {:ok, %{unit: unit} = _multi_result} ->
        {:ok, unit}

      {:error, changeset} ->
        {:error, changeset}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete(unit) do
    from(utu in UnitTypeUnit, where: utu.unit_id == ^unit.id) |> Repo.delete_all()
    Repo.delete(unit)
  end

  defp parse_list([""]), do: []
  defp parse_list(list), do: list
end
