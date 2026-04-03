defmodule Tpn.Orders do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Order

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
