defmodule Tpn.Repo.Migrations.CreateTablePatientMrns do
  use Ecto.Migration

  def change do
    create table(:patient_mrns) do
      add :mrn, :string, null: false
      add :patient_id, references(:patients, on_delete: :delete_all), null: false

      add :local_health_network_id, references(:local_health_networks, on_delete: :nilify_all),
        null: false

      add :facility_id, references(:facilities, on_delete: :nilify_all), null: false
      add :campus_id, references(:campuses, on_delete: :nilify_all), null: false
      add :admission_id, references(:admissions, on_delete: :nilify_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:patient_mrns, [:mrn, :campus_id], name: :unique_mrn_per_campus)

    execute """
      CREATE OR REPLACE VIEW admissions_view AS
      SELECT a.id,
             a.admission_no,
             a.discharged,
             a.discharged_at,
             a.age,
             a.notes,
             a.patient_weight,
             a.patient_height,
             a.weight_unit_id,
             a.height_unit_id,
             a.patient_id,
             a.patient_type_id,
             a.local_health_network_id,
             a.facility_id,
             a.campus_id,
             a.ward_id,
             a.room_id,
             a.bed_id,
             a.user_id,
             a.inserted_at,
             a.updated_at,
             p.first_name,
             p.last_name,
             p.identity_no,
             p.tpn_id,
             pt.name AS patient_type,
             lhn.name AS local_health_network,
            f.name AS facility,
            c.name AS campus,
            w.name AS ward,
            r.name AS room,
            b.name AS bed,
            mr.mrn,
            wu.unit AS weight_unit,
            hu.unit AS height_unit,
            u.first_name AS user_name
            FROM admissions a
            JOIN patients p ON a.patient_id = p.id
            JOIN patient_types pt ON a.patient_type_id = pt.id
            JOIN local_health_networks lhn ON a.local_health_network_id = lhn.id
            JOIN facilities f ON a.facility_id = f.id
            JOIN campuses c ON a.campus_id = c.id
            LEFT JOIN wards w ON a.ward_id = w.id
            LEFT JOIN rooms r ON a.room_id = r.id
            LEFT JOIN beds b ON a.bed_id = b.id
            LEFT JOIN users u ON a.user_id = u.id
            LEFT JOIN patient_mrns mr ON a.id = mr.admission_id
            LEFT JOIN units wu ON a.weight_unit_id = wu.id
            LEFT JOIN units hu ON a.height_unit_id = hu.id
    """
  end
end
