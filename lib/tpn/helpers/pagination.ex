defmodule Tpn.Helpers.PaginationHelper do
  import Ecto.Query, warn: false

  @page_size 20

  def build_networks_query(query, conn) do
    case conn.assigns[:is_admin] do
      true ->
        query

      _ ->
        current_user = conn.assigns[:current_user]

        query
        |> insert_network_where_clause("lhn", current_user.local_health_network_id)
        |> insert_network_where_clause("facility", current_user.facility_id)
        |> insert_network_where_clause("campus", current_user.campus_id)
        |> insert_network_user_where_clause(conn)
    end
  end

  @doc """
  builds query for pagination based on parameters.
  """
  def build_query_params(query, schema, params, sub \\ false) do
    # if params.page is nil, set it to 1
    params = Map.put_new(params, "page", "1")
    # if params.order_by is nil, set it to :inserted_at
    params = Map.put_new(params, "order_by", "inserted_at")
    # if params.order_direction is nil, set it to :desc
    params = Map.put_new(params, "order_direction", "desc")
    # if filter is nil, set it to %{}
    params = Map.put_new(params, "filter", "")

    filter_fields =
      case params["filter_by"] do
        nil -> schema.filter_fields()
        _ -> [String.to_atom(params["filter_by"])]
      end

    # get filterable fields from schema
    filterable_fields =
      filter_fields
      |> filter_params_for_admin(params, sub)

    page = String.to_integer(params["page"])

    order_by = String.to_atom(params["order_by"])
    order_direction = String.to_atom(params["order_direction"])

    query
    |> build_ilike_where_clause(filterable_fields, schema, params["filter"], sub)
    |> limit(@page_size)
    |> offset((^page - 1) * ^@page_size)
    |> order_by([{^order_direction, ^order_by}])
  end

  @doc """
  gets total pages based on query and params.
  """
  def get_paging_meta(query, params, schema) do
    current_page = String.to_integer(Map.get(params, "page", "1"))
    records = Tpn.Repo.aggregate(query, :count, :id)
    total_pages = ceil(records / @page_size)

    %{
      total_pages: ceil(records / @page_size),
      has_next_page: current_page < total_pages,
      has_previous_page: current_page > 1,
      next_page: current_page + 1,
      previous_page: current_page - 1,
      current_page: current_page,
      filter: Map.get(params, "filter", ""),
      order_by: Map.get(params, "order_by", "inserted_at"),
      order_direction: Map.get(params, "order_direction", "desc"),
      sortable_fields: schema.sortable_fields()
    }
  end

  defp build_ilike_where_clause(query, filterable_fields, schema, filter, sub) do
    case filter do
      "" ->
        query

      _ ->
        if sub do
          sub_query =
            Enum.reduce(filterable_fields, schema, fn key, schema ->
              from q in schema, or_where: ilike(field(q, ^key), ^"%#{filter}%")
            end)
            |> select([q], q.id)

          where(query, [q], q.id in subquery(sub_query))
        else
          Enum.reduce(filterable_fields, schema, fn key, schema ->
            from q in schema, or_where: ilike(field(q, ^key), ^"%#{filter}%")
          end)
        end
    end
  end

  defp filter_params_for_admin(filterable_fields, _, false), do: filterable_fields

  defp filter_params_for_admin(filterable_fields, params, true) do
    filterable_fields
    |> Enum.reject(&(&1 in [:local_health_network, :user_name]))
    |> reject_fields(params)
  end

  defp reject_fields(filterable_fields, params) do
    filterable_fields =
      if !is_nil(params["campus_id"]) do
        filterable_fields
        |> Enum.reject(&(&1 == :campus))
      else
        filterable_fields
      end

    if !is_nil(params["facility_id"]) do
      filterable_fields
      |> Enum.reject(&(&1 == :facility))
    else
      filterable_fields
    end
  end

  defp insert_network_where_clause(query, _, nil), do: query
  defp insert_network_where_clause(query, _, ""), do: query

  defp insert_network_where_clause(query, "lhn", id),
    do: query |> where([q], q.local_health_network_id == ^id)

  defp insert_network_where_clause(query, "facility", id),
    do: query |> where([q], q.facility_id == ^id)

  defp insert_network_where_clause(query, "campus", id),
    do: query |> where([q], q.campus_id == ^id)

  defp insert_network_user_where_clause(query, _conn) do
    query
    # for some request paths we need to filter by user_id
    # this is the case for the user's own records
    # and for the records that the user has created
    # so we need to filter by user_id
    # query
    # |> where([q], q.user_id == ^conn.assigns[:current_user].id)
  end
end
