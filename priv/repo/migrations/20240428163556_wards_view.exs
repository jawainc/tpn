defmodule Tpn.Repo.Migrations.WardsView do
  use Ecto.Migration

  def change do
    execute """
    CREATE OR REPLACE VIEW wards_view AS
    SELECT
      w.id,
      w.name,
      w.code,
      w.local_health_network_id,
      w.facility_id,
      w.campus_id,
      w.user_id,
      w.inserted_at,
      lhn.name AS local_health_network,
      f.name AS facility,
      c.name AS campus,
      u.first_name AS user_name
    FROM wards w
    LEFT JOIN local_health_networks lhn ON w.local_health_network_id = lhn.id
    LEFT JOIN facilities f ON w.facility_id = f.id
    LEFT JOIN campuses c ON w.campus_id = c.id
    LEFT JOIN users u ON w.user_id = u.id
    """
  end
end
