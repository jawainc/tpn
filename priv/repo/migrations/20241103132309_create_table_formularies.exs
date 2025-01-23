defmodule Tpn.Repo.Migrations.CreateTableFormularies do
  use Ecto.Migration

  def change do
    create table(:formularies) do
      add :name, :string, null: false
      add :label_friendly_name, :string, size: 50, null: false
      add :code, :string, size: 10, null: false
      add :is_enteral, :boolean, default: false
      add :concentration, :decimal, precision: 10, scale: 2, null: false
      add :calories, :decimal, precision: 10, scale: 2, null: false
      add :cost_per_container, :decimal, precision: 10, scale: 2, null: true
      add :container_size, :decimal, precision: 10, scale: 2, null: true
      add :print_on_label, :boolean, default: false
      add :include_in_overfill, :boolean, default: false
      add :universal_fluid, :boolean, default: false

      add :class_id, references(:classes, on_delete: :nilify_all), null: false
      add :concentration_unit_id, references(:units, on_delete: :nilify_all), null: false
      add :calories_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :uom_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :solution_type_id, references(:solution_types, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps(type: :utc_datetime)
    end

    create table(:formulary_ingredients) do
      add :formulary_id, references(:formularies, on_delete: :delete_all), null: false
      add :ingredient_id, references(:ingredients, on_delete: :delete_all), null: false
      add :unit_id, references(:units, on_delete: :delete_all), null: false
      add :amount, :decimal, precision: 10, scale: 2, null: true
    end

    create table(:formulary_patient_types) do
      add :formulary_id, references(:formularies, on_delete: :delete_all), null: false
      add :patient_type_id, references(:patient_types, on_delete: :delete_all), null: false
    end

    create unique_index(:formularies, [:name])
    create unique_index(:formulary_patient_types, [:formulary_id, :patient_type_id])
    create unique_index(:formulary_ingredients, [:formulary_id, :ingredient_id])

    execute """
      CREATE OR REPLACE VIEW formularies_view AS
      SELECT f.id,
      f.name,
      f.label_friendly_name,
      f.code,
      f.is_enteral,
      f.concentration,
      f.calories,
      f.cost_per_container,
      f.container_size,
      f.print_on_label,
      f.include_in_overfill,
      f.universal_fluid,
      f.class_id,
      f.concentration_unit_id,
      f.calories_unit_id,
      f.uom_unit_id,
      f.solution_type_id,
      f.user_id,
      f.inserted_at,
      f.updated_at,
      c.name as class_name,
      cu.unit as concentration_unit_name,
      calu.unit as calories_unit_name,
      uomu.unit as uom_unit_name,
      st.name as solution_type_name,
      u.first_name as user_name
      FROM formularies f
      LEFT JOIN classes c ON f.class_id = c.id
      LEFT JOIN units cu ON f.concentration_unit_id = cu.id
      LEFT JOIN units calu ON f.calories_unit_id = calu.id
      LEFT JOIN units uomu ON f.uom_unit_id = uomu.id
      LEFT JOIN solution_types st ON f.solution_type_id = st.id
      LEFT JOIN users u ON f.user_id = u.id
    """
  end
end
