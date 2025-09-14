defmodule TpnWeb.Helpers.Networks do
  @moduledoc """
  This module is used to handle networks for the user.
  """
  use TpnWeb, :controller

  import Ecto.Query, warn: false
  alias Tpn.Repo

  alias Tpn.Accounts.Networks.{LocalHealthNetwork, Facility, Campus}

  @doc """
  This function is used to get the user network access.
  """
  def get_user_network_access(conn) do
    current_user = conn.assigns[:current_user]

    cond do
      conn.assigns[:is_admin] ->
        {:ok, %{:lhn_id => nil, :facility_id => nil, :campus_id => nil}}

      !is_nil(current_user.campus_id) ->
        {:ok, %{:lhn_id => nil, :facility_id => nil, :campus_id => current_user.campus_id}}

      !is_nil(current_user.facility_id) ->
        {:ok, %{:lhn_id => nil, :facility_id => current_user.facility_id, :campus_id => nil}}

      !is_nil(current_user.local_health_network_id) ->
        {:ok,
         %{
           :lhn_id => current_user.local_health_network_id,
           :facility_id => nil,
           :campus_id => nil
         }}

      true ->
        {:error, %{}}
    end
  end

  def params_assign_user(conn, params) do
    current_user = conn.assigns[:current_user]

    params
    |> insert_user(current_user.id)
  end

  def params_assign_networks(conn, params) do
    current_user = conn.assigns[:current_user]

    case conn.assigns[:is_admin] do
      true ->
        params |> insert_user(current_user.id)

      _ ->
        params
        |> insert_user(current_user.id)
        |> insert_netwrork("lhn", current_user.local_health_network_id)
        |> insert_netwrork("facility", current_user.facility_id)
        |> insert_netwrork("campus", current_user.campus_id)
    end
  end

  def assign_networks(conn, lhn_id \\ nil, facility_id \\ nil) do
    case conn.assigns[:is_admin] do
      true ->
        conn
        |> assign(:lhns, get_lhns())
        |> assign(:facilities, get_facilities(lhn_id))
        |> assign(:campuses, get_campuses(facility_id))

      false ->
        lhn_id =
          if is_nil(lhn_id) do
            conn.assigns[:current_user].local_health_network_id
          else
            lhn_id
          end

        facility_id =
          if is_nil(facility_id) do
            conn.assigns[:current_user].facility_id
          else
            facility_id
          end

        conn
        |> assign(:lhns, [])
        |> assign(:facilities, get_facilities(lhn_id))
        |> assign(:campuses, get_campuses(facility_id))
    end
  end

  def get_wards(record) do
    where_q =
      (fn ->
         cond do
           record.campus_id ->
             %{type: :campus, id: record.campus_id}

           record.facility_id ->
             %{type: :facility, id: record.facility_id}

           record.local_health_network_id ->
             %{type: :lhn, id: record.local_health_network_id}

           true ->
             %{type: nil, id: nil}
         end
       end).()

    Tpn.Hospital.Ward
    |> network_where_query(where_q)
    |> order_by(asc: :name)
    |> Tpn.Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def network_where_query(query, %{type: :campus, id: id}) do
    query
    |> where([q], q.campus_id == ^id)
  end

  def network_where_query(query, %{type: :facility, id: id}) do
    query
    |> where([q], q.facility_id == ^id)
  end

  def network_where_query(query, %{type: :lhn, id: id}) do
    query
    |> where([q], q.local_health_network_id == ^id)
  end

  def network_where_query(query, _), do: query

  defp get_lhns() do
    LocalHealthNetwork
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp get_facilities(nil), do: []

  defp get_facilities(lhn_id) do
    Facility
    |> where([f], f.local_health_network_id == ^lhn_id)
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp get_campuses(nil), do: []

  defp get_campuses(facility_id) do
    Campus
    |> where([c], c.facility_id == ^facility_id)
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp insert_netwrork(params, _, nil), do: params
  defp insert_netwrork(params, _, ""), do: params

  defp insert_netwrork(params, "lhn", id) do
    if !Map.has_key?(params, "local_health_network_id"),
      do: Map.put(params, "local_health_network_id", id)
  end

  defp insert_netwrork(params, "facility", id) do
    if !Map.has_key?(params, "facility_id"), do: Map.put(params, "facility_id", id)
  end

  defp insert_netwrork(params, "campus", id) do
    if !Map.has_key?(params, "campus_id"), do: Map.put(params, "campus_id", id)
  end

  defp insert_user(params, id), do: Map.put(params, "user_id", id)
end
