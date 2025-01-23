defmodule Tpn.FillingMethods do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.FillingMethod
  alias Tpn.Helpers.PaginationHelper

  def filling_methods() do
    Repo.all(FillingMethod, order_by: [asc: :name])
  end

  def list_filling_methods(params) do
    filling_methods =
      from(f in FillingMethod)
      |> PaginationHelper.build_query_params(FillingMethod, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(f in FillingMethod)
      |> PaginationHelper.get_paging_meta(params, FillingMethod)

    {:ok, {filling_methods, meta}}
  end

  def filling_methods_for_select do
    from(f in FillingMethod, order_by: [asc: :name])
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_filling_method(params) do
    %FillingMethod{}
    |> FillingMethod.changeset(params)
    |> Repo.insert()
  end

  def get_filling_method!(id) do
    Repo.get!(FillingMethod, id)
  end

  def change_filling_method(filling_method) do
    FillingMethod.changeset(filling_method, %{})
  end

  def update_filling_method(filling_method, params) do
    filling_method
    |> FillingMethod.changeset(params)
    |> Repo.update()
  end

  def delete_filling_method(filling_method) do
    Repo.delete(filling_method)
  end
end
