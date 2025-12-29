defmodule Tpn.Repo.Migrations.AddOsmolarityFieldToOsmolarities do
  use Ecto.Migration

  def change do
    # Add column as nullable first to handle existing records
    alter table(:osmolarities) do
      add :osmolarity, :decimal, precision: 10, scale: 4, null: true
    end

    # Set a default value for existing records (0.0)
    execute "UPDATE osmolarities SET osmolarity = 0.0 WHERE osmolarity IS NULL"

    # Now make it NOT NULL
    alter table(:osmolarities) do
      modify :osmolarity, :decimal, precision: 10, scale: 4, null: false
    end

    # Drop and recreate the view to include the new osmolarity field
    execute "DROP VIEW IF EXISTS osmolarities_view"

    execute """
    CREATE VIEW osmolarities_view AS
    SELECT
      o.id,
      o.name,
      o.osmolarity,
      o.unit_id,
      o.vascular_access_id,
      o.patient_type_id,
      o.user_id,
      o.inserted_at,
      u.first_name AS user_name,
      un.unit AS unit,
      v.name AS vascular_access,
      p.name AS patient_type
    FROM osmolarities o
    LEFT JOIN units un ON o.unit_id = un.id
    LEFT JOIN vascular_accesses v ON o.vascular_access_id = v.id
    LEFT JOIN patient_types p ON o.patient_type_id = p.id
    LEFT JOIN users u ON o.user_id = u.id
    """
  end
end
