defmodule Tpn.Hospital.Wards do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Hospital.{WardsView, Ward}
  alias Tpn.Helpers.PaginationHelper

  def list_wards(params, conn) do
    params =
      params
      |> Map.put_new(
        "local_health_network_id",
        conn.assigns[:current_user].local_health_network_id
      )
      |> Map.put_new("facility_id", conn.assigns[:current_user].facility_id)
      |> Map.put_new("campus_id", conn.assigns[:current_user].campus_id)

    users =
      from(a in WardsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(WardsView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in WardsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, WardsView)

    {:ok, {users, meta}}
  end

  def create_ward(params) do
    %Ward{}
    |> Ward.changeset(params)
    |> Repo.insert()
  end

  def get_ward!(id) do
    Repo.get!(Ward, id)
  end

  def get_wards_for_select_by_campus_id(campus_id) do
    from(w in Ward, where: w.campus_id == ^campus_id)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def change_ward(ward) do
    Ward.changeset(ward, %{})
  end

  def update_ward(ward, params) do
    ward
    |> Ward.changeset(params)
    |> Repo.update()
  end

  def delete_ward(ward) do
    Repo.delete(ward)
  end
end
