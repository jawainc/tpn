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

  def get_osmolarities_by_patient_type(patient_type_id) do
    from(o in Osmolarity,
      where: o.patient_type_id == ^patient_type_id,
      preload: [:vascular_access, :patient_type],
      order_by: [asc: :vascular_access_id]
    )
    |> Repo.all()
    |> Enum.map(fn o ->
      %{
        id: o.id,
        osmolarity: Decimal.to_float(o.osmolarity),
        alert_type: o.alert_type,
        vascular_access_id: o.vascular_access_id,
        vascular_access_name: o.vascular_access.name,
        patient_type_id: o.patient_type_id
      }
    end)
  end
end
