defmodule Tpn.Repo.Migrations.AddIndexesForOrdersPerformance do
  use Ecto.Migration

  def change do
    # Index on admissions.campus_id for faster network filtering
    create_if_not_exists index(:admissions, [:campus_id])
    
    # Index on orders.status for status filtering
    create_if_not_exists index(:orders, [:status])
    
    # Index on orders.order_date for date sorting and filtering
    create_if_not_exists index(:orders, [:order_date])
    
    # Index on orders.order_type for filtering by patient/bulk
    create_if_not_exists index(:orders, [:order_type])
    
    # Composite index for common query pattern: status + order_date DESC
    create_if_not_exists index(:orders, [:status, :order_date], 
      name: :orders_status_date_idx,
      comment: "Composite index for filtering by status and sorting by date"
    )
    
    # Composite index for order_type + order_date DESC
    create_if_not_exists index(:orders, [:order_type, :order_date],
      name: :orders_type_date_idx,
      comment: "Composite index for filtering by type and sorting by date"
    )
  end
end
