defmodule Tpn.Repo.Migrations.BedsView do
  use Ecto.Migration

  def change do
    execute """
    CREATE OR REPLACE VIEW beds_view AS
    SELECT
      b.id,
      b.name,
      b.code,
      b.local_health_network_id,
      b.facility_id,
      b.campus_id,
      b.user_id,
      b.inserted_at,
      w.name AS ward,
      r.name AS room,
      u.first_name AS user_name,
      lhn.name AS local_health_network,
      f.name AS facility,
      c.name AS campus
    FROM beds b
    LEFT JOIN wards w ON b.ward_id = w.id
    LEFT JOIN rooms r ON b.room_id = r.id
    LEFT JOIN local_health_networks lhn ON b.local_health_network_id = lhn.id
    LEFT JOIN facilities f ON b.facility_id = f.id
    LEFT JOIN campuses c ON b.campus_id = c.id
    LEFT JOIN users u ON b.user_id = u.id
    """
  end
end
