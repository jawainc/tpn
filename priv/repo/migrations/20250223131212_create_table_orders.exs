defmodule Tpn.Repo.Migrations.CreateTableOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :order_type, :string, default: "patient", null: false
      add :status, :string, default: "draft", null: false
      add :order_id, :string, null: false
      add :bag_id, :string, null: false
      add :order_date, :naive_datetime, default: fragment("NOW()"), null: false
      add :copy_order, :boolean, default: false, null: false
      add :number_of_bags, :integer, default: 1, null: false
      add :enteral_dose, :decimal, precision: 10, scale: 2, null: true
      add :tpn_infusion_type, :string, null: true
      add :infusion_duration_type, :string, null: true
      add :tpn_infusion_duration_hours, :integer, null: true
      add :lipid_infusion_duration_hours, :integer, null: true
      add :dosing_weight, :string, null: true
      add :template_fluids, :map, default: %{}, null: false
      add :template_properties, :map, default: %{}, null: false
      add :using_premixed_bag, :boolean, default: false, null: false
      add :premixed_bag_batch_number, :string, null: true
      add :premixed_bag_expiry, :naive_datetime, null: true

      add :template_id, references(:templates, on_delete: :nilify_all), null: false
      add :formulary_id, references(:formularies, on_delete: :nilify_all), null: true
      add :vascular_access_id, references(:vascular_accesses, on_delete: :nilify_all), null: true
      add :copied_from_order_id, references(:orders, on_delete: :nilify_all), null: true
      add :admission_id, references(:admissions, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nothing), null: false

      add :total_price, :decimal, precision: 10, scale: 2

      timestamps()
    end

    create index(:orders, [:user_id])
  end
end
