defmodule Tpn.Repo.Migrations.CreateViewUsersRoles do
  use Ecto.Migration

  def change do
    execute """
    CREATE or REPLACE VIEW users_roles AS
    SELECT
      users.id,
      users.first_name,
      users.last_name,
      users.email,
      users.contact_no,
      users.active,
      users.deleted,
      users.role_id,
      roles.name AS role,
      local_health_networks.name AS local_health_network,
      facilities.name AS facility,
      campuses.name AS campus,
      users.inserted_at
    FROM
      users
    LEFT JOIN
      roles ON users.role_id = roles.id
    LEFT JOIN
      local_health_networks ON users.local_health_network_id = local_health_networks.id
    LEFT JOIN
      facilities ON users.facility_id = facilities.id
    LEFT JOIN
      campuses ON users.campus_id = campuses.id
    WHERE
      users.deleted = false
    """
  end
end
