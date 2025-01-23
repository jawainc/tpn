defmodule Tpn.VascularAccesses do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.VascularAccess
  alias Tpn.Helpers.PaginationHelper

  def vascular_accesses() do
    Repo.all(VascularAccess, order_by: [asc: :name])
  end

  def list_vascular_accesses(params) do
    vascular_accesses =
      from(va in VascularAccess)
      |> PaginationHelper.build_query_params(VascularAccess, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(va in VascularAccess)
      |> PaginationHelper.get_paging_meta(params, VascularAccess)

    {:ok, {vascular_accesses, meta}}
  end

  def vascular_accesses_for_select do
    VascularAccess
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_vascular_access(params) do
    %VascularAccess{}
    |> VascularAccess.changeset(params)
    |> Repo.insert()
  end

  def get_vascular_access!(id) do
    Repo.get!(VascularAccess, id)
  end

  def change_vascular_access(vascular_access) do
    VascularAccess.changeset(vascular_access, %{})
  end

  def update_vascular_access(vascular_access, params) do
    vascular_access
    |> VascularAccess.changeset(params)
    |> Repo.update()
  end

  def delete_vascular_access(vascular_access) do
    Repo.delete(vascular_access)
  end
end
