defmodule Tpn.SolutionTypes do
  import Ecto.Query
  alias Tpn.Repo
  alias Tpn.SolutionType
  alias Tpn.Helpers.PaginationHelper

  def solution_types() do
    Repo.all(SolutionType, order_by: [asc: :name])
  end

  def list_solution_types(params) do
    solution_types =
      from(st in SolutionType)
      |> PaginationHelper.build_query_params(SolutionType, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(st in SolutionType)
      |> PaginationHelper.get_paging_meta(params, SolutionType)

    {:ok, {solution_types, meta}}
  end

  def solution_types_for_select do
    from(st in SolutionType, order_by: [asc: :name])
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_solution_type(params) do
    %SolutionType{}
    |> SolutionType.changeset(params)
    |> Repo.insert()
  end

  def get_solution_type!(id) do
    Repo.get!(SolutionType, id)
  end

  def change_solution_type(solution_type) do
    SolutionType.changeset(solution_type, %{})
  end

  def update_solution_type(solution_type, params) do
    solution_type
    |> SolutionType.changeset(params)
    |> Repo.update()
  end

  def delete_solution_type(solution_type) do
    Repo.delete(solution_type)
  end
end
