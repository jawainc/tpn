defmodule Tpn.Orders do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.{Order, Admission, Patient}
  alias Tpn.Accounts.Networks.{Campus, Facility, LocalHealthNetwork}
  alias Tpn.Helpers.PaginationHelper

  def list_orders() do
    orders =
      from(o in Order, order_by: [desc: o.id])
      |> Repo.all()

    orders
  end

  def list_orders_by_admission_id(admission_id) do
    orders =
      from(o in Order)
      |> where([o], o.admission_id == ^admission_id)
      |> Repo.all()

    orders
  end

  def list_orders_by_patient_id(patient_id) do
    orders =
      from(o in Order)
      |> where([o], o.patient_id == ^patient_id)
      |> Repo.all()

    orders
  end

  @doc """
  List orders for user based on network access with filtering and pagination.

  ## Parameters
  - lhn_id: Local Health Network ID (nil for admin or if not LHN user)
  - facility_id: Facility ID (nil if admin or LHN user)
  - campus_id: Campus ID (nil if not campus user)
  - params: Map with optional filters:
    - "search" - Search by patient name, bag_id, or MRN
    - "status" - Filter by order status
    - "order_type" - Filter by Patient Specific or Batch Production
    - "date_from" - Filter orders from this date
    - "date_to" - Filter orders to this date
    - "page" - Page number for pagination
    - "page_size" - Items per page (default: 25)
    - "sort_by" - Field to sort by (default: order_date)
    - "sort_order" - asc or desc (default: desc)

  ## Returns
  {:ok, {orders, meta}} where meta contains pagination info
  """
  def list_orders_for_user(lhn_id, facility_id, campus_id, params \\ %{}) do
    base_query()
    |> apply_network_filter(lhn_id, facility_id, campus_id)
    |> apply_filters(params)
    |> apply_sorting(params)
    |> paginate_orders(params)
  end

  @doc """
  Get a single order with all associations preloaded.
  """
  def get_order!(id) do
    base_query()
    |> where([o], o.id == ^id)
    |> Repo.one!()
  end

  # Private helper functions

  defp base_query do
    from o in Order,
      left_join: p in Patient,
      on: o.patient_id == p.id,
      left_join: a in Admission,
      on: o.admission_id == a.id,
      left_join: c in Campus,
      on: a.campus_id == c.id,
      left_join: f in Facility,
      on: c.facility_id == f.id,
      left_join: lhn in LocalHealthNetwork,
      on: f.local_health_network_id == lhn.id,
      select: %{
        id: o.id,
        order_type: o.order_type,
        status: o.status,
        bag_id: o.bag_id,
        order_date: o.order_date,
        patient_id: o.patient_id,
        patient_name: fragment("CONCAT(?, ' ', ?)", p.first_name, p.last_name),
        admission_id: o.admission_id,
        campus_id: c.id,
        campus_name: c.name,
        facility_id: f.id,
        facility_name: f.name,
        lhn_id: lhn.id,
        lhn_name: lhn.name,
        inserted_at: o.inserted_at,
        updated_at: o.updated_at
      }
  end

  defp apply_network_filter(query, nil, nil, nil) do
    # Admin user - see all orders
    query
  end

  defp apply_network_filter(query, nil, nil, campus_id) when not is_nil(campus_id) do
    # Campus user - see only campus orders
    query |> where([o, p, a, c], c.id == ^campus_id)
  end

  defp apply_network_filter(query, nil, facility_id, nil) when not is_nil(facility_id) do
    # Facility user - see all facility orders
    query |> where([o, p, a, c, f], f.id == ^facility_id)
  end

  defp apply_network_filter(query, lhn_id, nil, nil) when not is_nil(lhn_id) do
    # LHN user - see all LHN orders
    query |> where([o, p, a, c, f, lhn], lhn.id == ^lhn_id)
  end

  defp apply_network_filter(query, _, _, _), do: query

  defp apply_filters(query, params) do
    query
    |> apply_search_filter(params)
    |> apply_status_filter(params)
    |> apply_order_type_filter(params)
    |> apply_date_range_filter(params)
  end

  defp apply_search_filter(query, %{"search" => search})
       when is_binary(search) and search != "" do
    search_term = "%#{search}%"

    query
    |> where(
      [o, p],
      ilike(fragment("CONCAT(?, ' ', ?)", p.first_name, p.last_name), ^search_term) or
        ilike(o.bag_id, ^search_term)
    )
  end

  defp apply_search_filter(query, _), do: query

  defp apply_status_filter(query, %{"status" => status})
       when is_binary(status) and status != "" do
    query |> where([o], o.status == ^status)
  end

  defp apply_status_filter(query, _), do: query

  defp apply_order_type_filter(query, %{"order_type" => order_type})
       when is_binary(order_type) and order_type != "" do
    query |> where([o], o.order_type == ^order_type)
  end

  defp apply_order_type_filter(query, _), do: query

  defp apply_date_range_filter(query, %{"date_from" => date_from, "date_to" => date_to})
       when is_binary(date_from) and is_binary(date_to) do
    with {:ok, from_date} <- parse_date(date_from),
         {:ok, to_date} <- parse_date(date_to) do
      query |> where([o], o.order_date >= ^from_date and o.order_date <= ^to_date)
    else
      _ -> query
    end
  end

  defp apply_date_range_filter(query, %{"date_from" => date_from}) when is_binary(date_from) do
    case parse_date(date_from) do
      {:ok, from_date} -> query |> where([o], o.order_date >= ^from_date)
      _ -> query
    end
  end

  defp apply_date_range_filter(query, %{"date_to" => date_to}) when is_binary(date_to) do
    case parse_date(date_to) do
      {:ok, to_date} -> query |> where([o], o.order_date <= ^to_date)
      _ -> query
    end
  end

  defp apply_date_range_filter(query, _), do: query

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, NaiveDateTime.new!(date, ~T[00:00:00])}
      error -> error
    end
  end

  defp apply_sorting(query, %{"sort_by" => "patient_name", "sort_order" => "asc"}) do
    query |> order_by([o, p], asc: fragment("CONCAT(?, ' ', ?)", p.first_name, p.last_name))
  end

  defp apply_sorting(query, %{"sort_by" => "patient_name", "sort_order" => "desc"}) do
    query |> order_by([o, p], desc: fragment("CONCAT(?, ' ', ?)", p.first_name, p.last_name))
  end

  defp apply_sorting(query, %{"sort_by" => "status", "sort_order" => "asc"}) do
    query |> order_by([o], asc: o.status)
  end

  defp apply_sorting(query, %{"sort_by" => "status", "sort_order" => "desc"}) do
    query |> order_by([o], desc: o.status)
  end

  defp apply_sorting(query, %{"sort_by" => "order_date", "sort_order" => "asc"}) do
    query |> order_by([o], asc: o.order_date)
  end

  defp apply_sorting(query, %{"sort_order" => "asc"}) do
    query |> order_by([o], asc: o.order_date)
  end

  defp apply_sorting(query, _) do
    # Default: sort by order_date descending (latest first)
    query |> order_by([o], desc: o.order_date)
  end

  defp paginate_orders(query, params) do
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "25")

    offset = (page - 1) * page_size

    # Get total count
    total_count = query |> exclude(:select) |> exclude(:order_by) |> Repo.aggregate(:count)

    # Get paginated results
    orders =
      query
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    # Calculate pagination metadata
    total_pages = ceil(total_count / page_size)

    meta = %{
      current_page: page,
      page_size: page_size,
      total_count: total_count,
      total_pages: total_pages,
      has_next: page < total_pages,
      has_prev: page > 1
    }

    {:ok, {orders, meta}}
  end

  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update order status with validation and logging.

  ## Parameters
  - order_id: ID of the order to update
  - status: New status (draft, pending, approved, rejected)
  - user_id: ID of the user making the change

  ## Returns
  - {:ok, order} if successful
  - {:error, changeset} if validation fails
  """
  def update_order_status(order_id, status, user_id) do
    order = Repo.get!(Order, order_id)

    changeset =
      order
      |> Order.changeset(%{status: status})
      |> Ecto.Changeset.put_change(:user_id, user_id)

    case Repo.update(changeset) do
      {:ok, updated_order} ->
        # Log the status change
        log_status_change(updated_order, user_id)
        {:ok, updated_order}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp log_status_change(order, user_id) do
    snapshot = %{
      order_id: order.id,
      status: order.status,
      changed_at: NaiveDateTime.utc_now(),
      changed_by_user_id: user_id,
      osmolarity_alert: order.osmolarity_alert,
      infusion_calculations: order.infusion_calculations,
      nutritional_calculations: order.nutritional_calculations
    }

    IO.inspect(snapshot, label: "Order status change logged")
  end

  @doc """
  Get order with calculation data and status history.

  ## Parameters
  - order_id: ID of the order

  ## Returns
  Order with preloaded calculation data
  """
  def get_order_with_snapshots(order_id) do
    order = Repo.get!(Order, order_id)

    # In a real implementation, you would preload status snapshots
    # For now, return the order with calculation fields
    order
  end
end
