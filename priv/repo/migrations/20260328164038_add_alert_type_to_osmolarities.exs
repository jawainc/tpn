defmodule Tpn.Repo.Migrations.AddAlertTypeToOsmolarities do
  use Ecto.Migration

  def change do
    # Add alert_type column to osmolarities with default "Soft" and not null
    alter table(:osmolarities) do
      add :alert_type, :string, null: false, default: "Soft"
    end

    # Drop the existing view
    execute "DROP VIEW IF EXISTS osmolarities_view"

    # Recreate the view with alert_type field
    execute """
    CREATE VIEW osmolarities_view AS
    SELECT
      o.id,
      o.name,
      o.osmolarity,
      o.alert_type,
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
