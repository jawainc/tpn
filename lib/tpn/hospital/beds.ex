defmodule Tpn.Hospital.Beds do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Hospital.{BedsView, Bed}
  alias Tpn.Helpers.PaginationHelper

  def list_beds(params, conn) do
    users =
      from(a in BedsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(BedsView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in BedsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, BedsView)

    {:ok, {users, meta}}
  end

  def create_bed(params) do
    %Bed{}
    |> Bed.changeset(params)
    |> Repo.insert()
  end

  def get_bed!(id) do
    Repo.get!(Bed, id)
  end

  def change_bed(bed) do
    Bed.changeset(bed, %{})
  end

  def update_bed(bed, params) do
    bed
    |> Bed.changeset(params)
    |> Repo.update()
  end

  def delete_bed(bed) do
    Repo.delete(bed)
  end
end
