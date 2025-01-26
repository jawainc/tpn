defmodule Tpn.Repo.Migrations.CreateTablePatients do
  use Ecto.Migration

  def change do
    create table(:patients) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :identity_no, :string, null: true
      add :dob, :date, null: false
      add :gender, :string, null: true
      add :address_1, :string, null: true
      add :address_2, :string, null: true
      add :city, :string, null: true
      add :state, :string, null: true
      add :country, :string, null: true
      add :zip, :string, null: true
      add :phone, :string, null: true
      add :email, :string, null: true
      add :notes, :text, null: true
      add :tpn_id, :string, null: false

      add :local_health_network_id, references(:local_health_networks, on_delete: :nilify_all),
        null: false

      add :facility_id, references(:facilities, on_delete: :nilify_all), null: false
      add :campus_id, references(:campuses, on_delete: :nilify_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create table(:admissions) do
      add :admission_no, :string, null: false
      add :discharged, :boolean, null: false, default: false
      add :discharged_at, :naive_datetime, null: true
      add :age, :string, null: false
      add :notes, :text, null: true
      add :patient_weight, :decimal, null: true
      add :patient_height, :decimal, null: true

      add :weight_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :height_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :patient_type_id, references(:patient_types, on_delete: :nilify_all), null: false

      add :local_health_network_id, references(:local_health_networks, on_delete: :nilify_all),
        null: false

      add :facility_id, references(:facilities, on_delete: :nilify_all), null: true
      add :campus_id, references(:campuses, on_delete: :nilify_all), null: true
      add :ward_id, references(:wards, on_delete: :nilify_all), null: true
      add :room_id, references(:rooms, on_delete: :nilify_all), null: true
      add :bed_id, references(:beds, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create index(:admissions, [:patient_id, :discharged_at])

    execute """
      CREATE OR REPLACE VIEW patients_view AS
      SELECT p.id,
          p.first_name,
          p.last_name,
          p.identity_no,
          p.dob,
          p.gender,
          p.address_1,
          p.address_2,
          p.city,
          p.state,
          p.country,
          p.zip,
          p.phone,
          p.email,
          p.notes,
          p.tpn_id,
          p.local_health_network_id,
          p.facility_id,
          p.campus_id,
          p.user_id,
          p.inserted_at,
          p.updated_at,
          lhn.name AS local_health_network,
          f.name AS facility,
          c.name AS campus,
          u.first_name as user_name,
          COALESCE(admission_status.is_admitted, FALSE) as is_admitted
      FROM patients p
      LEFT JOIN local_health_networks lhn ON p.local_health_network_id = lhn.id
      LEFT JOIN facilities f ON p.facility_id = f.id
      LEFT JOIN campuses c ON p.campus_id = c.id
      LEFT JOIN users u ON p.user_id = u.id
      LEFT JOIN LATERAL (
          SELECT TRUE as is_admitted
          FROM admissions a
          WHERE a.patient_id = p.id  -- Changed from f.id to p.id
          AND a.discharged_at IS NULL
          LIMIT 1
      ) admission_status ON TRUE;
    """
  end
end
