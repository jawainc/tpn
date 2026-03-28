defmodule Tpn.Repo.Migrations.AddOsmolarityToFormularies do
  use Ecto.Migration

  def change do
    # Add osmolarity column to formularies with 4 decimal places, default 0, not null
    alter table(:formularies) do
      add :osmolarity, :decimal, precision: 10, scale: 4, null: false, default: 0.0
    end

    # Drop the existing view
    execute "DROP VIEW IF EXISTS formularies_view"

    # Recreate the view with osmolarity field
    execute """
    CREATE VIEW formularies_view AS
    SELECT f.id,
    f.name,
    f.label_friendly_name,
    f.code,
    f.drug_id,
    f.is_enteral,
    f.concentration,
    f.calories,
    f.cost_per_container,
    f.container_size,
    f.print_on_label,
    f.include_in_overfill,
    f.universal_fluid,
    f.active,
    f.osmolarity,
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
