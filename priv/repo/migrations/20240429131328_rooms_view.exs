defmodule Tpn.Repo.Migrations.RoomsView do
  use Ecto.Migration

  def change do
    execute """
    CREATE OR REPLACE VIEW rooms_view AS
    SELECT
      r.id,
      r.name,
      r.code,
      r.local_health_network_id,
      r.facility_id,
      r.campus_id,
      r.user_id,
      r.inserted_at,
      w.name AS ward,
      u.first_name AS user_name,
      lhn.name AS local_health_network,
      f.name AS facility,
      c.name AS campus
    FROM rooms r
    LEFT JOIN wards w ON r.ward_id = w.id
    LEFT JOIN local_health_networks lhn ON r.local_health_network_id = lhn.id
    LEFT JOIN facilities f ON r.facility_id = f.id
    LEFT JOIN campuses c ON r.campus_id = c.id
    LEFT JOIN users u ON r.user_id = u.id
    """
  end
end
