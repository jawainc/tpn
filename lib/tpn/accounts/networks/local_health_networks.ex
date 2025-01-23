defmodule Tpn.Accounts.Networks.LocalHealthNetworks do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Helpers.PaginationHelper
  alias Tpn.Accounts.Networks.LocalHealthNetwork

  def list_local_health_networks(params \\ %{}) do
    local_health_networks =
      from(a in LocalHealthNetwork)
      |> PaginationHelper.build_query_params(LocalHealthNetwork, params)
      |> Repo.all()

    meta =
      from(a in LocalHealthNetwork)
      |> PaginationHelper.get_paging_meta(params, LocalHealthNetwork)

    {:ok, {local_health_networks, meta}}
  end

  def get_local_health_network!(id), do: Repo.get!(LocalHealthNetwork, id)

  def create_local_health_network(attrs \\ %{}) do
    %LocalHealthNetwork{}
    |> LocalHealthNetwork.changeset(attrs)
    |> Repo.insert()
  end

  def update_local_health_network(%LocalHealthNetwork{} = local_health_network, attrs) do
    local_health_network
    |> LocalHealthNetwork.changeset(attrs)
    |> Repo.update()
  end

  def delete_local_health_network(%LocalHealthNetwork{} = local_health_network) do
    Repo.delete(local_health_network)
  end

  def change_local_health_network(%LocalHealthNetwork{} = local_health_network, attrs \\ %{}) do
    LocalHealthNetwork.changeset(local_health_network, attrs)
  end
end
