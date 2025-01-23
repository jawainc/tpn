defmodule Tpn.Accounts.Networks.Facilities do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Helpers.PaginationHelper
  alias Tpn.Accounts.Networks.Facility

  def list_facilities(params \\ %{}) do
    facilities =
      from(a in Facility)
      |> PaginationHelper.build_query_params(Facility, params)
      |> preload(:local_health_network)
      |> Repo.all()

    meta =
      from(a in Facility)
      |> PaginationHelper.get_paging_meta(params, Facility)

    {:ok, {facilities, meta}}
  end

  def get_facility!(id), do: Repo.get!(Facility, id)

  def create_facility(attrs \\ %{}) do
    %Facility{}
    |> Facility.changeset(attrs)
    |> Repo.insert()
  end

  def update_facility(%Facility{} = facility, attrs) do
    facility
    |> Facility.changeset(attrs)
    |> Repo.update()
  end

  def delete_facility(%Facility{} = facility) do
    Repo.delete(facility)
  end

  def change_facility(%Facility{} = facility, attrs \\ %{}) do
    Facility.changeset(facility, attrs)
  end
end
