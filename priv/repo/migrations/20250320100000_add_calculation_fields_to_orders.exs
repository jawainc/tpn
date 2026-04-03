defmodule Tpn.Repo.Migrations.AddCalculationFieldsToOrders do
  use Ecto.Migration

  def change do
    # Add calculation fields to orders table
    alter table(:orders) do
      # Calculation fields
      add :infusion_calculations, :map, default: %{}, null: false
      add :nutritional_calculations, :map, default: %{}, null: false
      add :electrolyte_summary, :map, default: %{}, null: false
      add :nutritional_summary, :map, default: %{}, null: false
      add :osmolarity_alert, :map, default: %{}, null: false
      add :calculated_at, :utc_datetime, null: true

      # Osmolarity override fields
      add :osmolarity_overridden_at, :utc_datetime, null: true
      add :osmolarity_override_user_id, references(:users, on_delete: :nilify_all), null: true
      add :osmolarity_override_comments, :text, null: true

      # Add calculation config to templates table
    end

    # Create order_products table
    create table(:order_products) do
      # Foreign keys
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :formulary_id, references(:formularies, on_delete: :nilify_all), null: false

      # Product configuration
      add :position, :integer, default: 0, null: false
      add :class_id, :integer, null: false
      add :class_name, :string, null: false
      add :dose, :decimal, precision: 10, scale: 4, null: true
      add :dose_unit, :string, null: true
      add :filling_method_id, :integer, null: true
      add :filling_method_name, :string, null: true
      add :volume, :decimal, precision: 10, scale: 4, null: true
      add :fill_volume, :decimal, precision: 10, scale: 4, null: true
      add :additional_dose, :decimal, precision: 10, scale: 4, null: true
      add :additional_dose_unit, :string, null: true
      add :max_allowed_limit, :decimal, precision: 10, scale: 4, null: true
      add :max_allowed_unit, :string, null: true
      add :substance_locked_on_order, :boolean, default: false, null: false

      # Calculation fields
      add :osmolarity_contribution, :decimal, precision: 10, scale: 4, null: true
      add :electrolyte_contributions, :map, default: %{}, null: false

      timestamps()
    end

    # Add indexes for order_products
    create index(:order_products, [:order_id])
    create index(:order_products, [:formulary_id])
    create index(:order_products, [:class_id])
    create index(:order_products, [:position])

    # Add calculation fields to templates table
    alter table(:templates) do
      add :calculation_config, :map, default: %{}, null: false
      add :osmolarity_warning_threshold, :decimal, precision: 10, scale: 2, null: true
      add :osmolarity_error_threshold, :decimal, precision: 10, scale: 2, null: true
    end

    # Create status_snapshots table for audit trail
    create table(:status_snapshots) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :changed_at, :utc_datetime, null: false
      add :changed_by_user_id, references(:users, on_delete: :nilify_all), null: false

      # Snapshot of calculation data at status change
      add :osmolarity_alert, :map, default: %{}, null: false
      add :infusion_calculations, :map, default: %{}, null: false
      add :nutritional_calculations, :map, default: %{}, null: false
      add :electrolyte_summary, :map, default: %{}, null: false
      add :nutritional_summary, :map, default: %{}, null: false

      # Comments for status change
      add :comments, :text, null: true

      timestamps()
    end

    # Add indexes for status_snapshots
    create index(:status_snapshots, [:order_id])
    create index(:status_snapshots, [:status])
    create index(:status_snapshots, [:changed_at])
    create index(:status_snapshots, [:changed_by_user_id])
  end
end
