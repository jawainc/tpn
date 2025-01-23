defmodule Tpn.Lab.Osmolarities do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Lab.{Osmolarity, OsmolaritiesView}
  alias Tpn.Helpers.PaginationHelper

  def list_osmolarities(params, conn) do
    osmolarities =
      from(a in OsmolaritiesView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(OsmolaritiesView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in OsmolaritiesView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, OsmolaritiesView)

    {:ok, {osmolarities, meta}}
  end

  def osmolarities_for_select do
    Repo.all(Osmolarity)
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_osmolarity(params) do
    %Osmolarity{}
    |> Osmolarity.changeset(params)
    |> Repo.insert()
  end

  def get_osmolarity!(id) do
    Repo.get!(Osmolarity, id)
  end

  def change_osmolarity(osmolarity) do
    Osmolarity.changeset(osmolarity, %{})
  end

  def update_osmolarity(osmolarity, params) do
    osmolarity
    |> Osmolarity.changeset(params)
    |> Repo.update()
  end

  def delete_osmolarity(osmolarity) do
    Repo.delete(osmolarity)
  end
end
