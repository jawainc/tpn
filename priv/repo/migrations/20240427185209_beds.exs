defmodule Tpn.Repo.Migrations.Beds do
  use Ecto.Migration

  def change do
    create table(:beds) do
      add :name, :string
      add :code, :string

      add :local_health_network_id, references(:local_health_networks, on_delete: :nilify_all),
        null: true

      add :facility_id, references(:facilities, on_delete: :nilify_all), null: true
      add :campus_id, references(:campuses, on_delete: :nilify_all), null: true
      add :ward_id, references(:wards, on_delete: :nilify_all), null: true
      add :room_id, references(:rooms, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create index(:beds, [:room_id])
  end
end
